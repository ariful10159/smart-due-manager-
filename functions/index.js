const { onCall, HttpsError } = require('firebase-functions/v2/https')
const admin = require('firebase-admin')

admin.initializeApp()

const BATCH_LIMIT = 450

async function verifyCallerIsAdmin(request) {
  const callerUid = request.auth?.uid
  if (!callerUid) {
    throw new HttpsError('unauthenticated', 'Must be signed in.')
  }
  const adminDoc = await admin.firestore().collection('admins').doc(callerUid).get()
  if (!adminDoc.exists) {
    throw new HttpsError('permission-denied', 'Only admins can do this.')
  }
  return callerUid
}

async function deleteQuerySnapshotInBatches(snapshot) {
  const docs = snapshot.docs
  for (let i = 0; i < docs.length; i += BATCH_LIMIT) {
    const batch = admin.firestore().batch()
    docs.slice(i, i + BATCH_LIMIT).forEach((d) => batch.delete(d.ref))
    await batch.commit()
  }
}

// একজন user-এর সব ডেটা (customers, notebooks, প্রোফাইল, Auth account) মোছে — পুরোটাই
// server-side এ চলে, তাই admin panel-এর ব্রাউজার ট্যাব বন্ধ হয়ে গেলেও ডিলিট চলতে থাকে
// এবং শেষ হয়। ডিলিট বাই-ডিজাইন idempotent: একই uid দিয়ে আবার কল করলে যা যা আগেই মোছা
// হয়ে গেছে সেগুলো স্রেফ query-তে আর আসবে না, ফলে আগের কল মাঝপথে থেমে গেলেও এটা আবার
// কল করলে বাকি অংশ থেকে চালিয়ে সম্পূর্ণ করা যায় (safe to retry)।
exports.deleteUserData = onCall({ timeoutSeconds: 300 }, async (request) => {
  const callerUid = await verifyCallerIsAdmin(request)

  const targetUid = request.data?.uid
  if (!targetUid || typeof targetUid !== 'string') {
    throw new HttpsError('invalid-argument', 'A target uid is required.')
  }

  const db = admin.firestore()

  const customersSnap = await db.collection('customers').where('ownerId', '==', targetUid).get()
  for (const customerDoc of customersSnap.docs) {
    for (const sub of ['payments', 'reminders', 'smsLogs']) {
      const subSnap = await db.collection('customers').doc(customerDoc.id).collection(sub).get()
      await deleteQuerySnapshotInBatches(subSnap)
    }
  }
  await deleteQuerySnapshotInBatches(customersSnap)

  const notebooksSnap = await db.collection('notebooks').where('ownerId', '==', targetUid).get()
  for (const notebookDoc of notebooksSnap.docs) {
    const pagesSnap = await db.collection('notebooks').doc(notebookDoc.id).collection('pages').get()
    await deleteQuerySnapshotInBatches(pagesSnap)
  }
  await deleteQuerySnapshotInBatches(notebooksSnap)

  await db.collection('users').doc(targetUid).delete()

  let alreadyDeleted = false
  try {
    await admin.auth().deleteUser(targetUid)
  } catch (err) {
    // ইতিমধ্যে Auth থেকে ডিলিট হয়ে গেলে (যেমন partial failure এর পর আবার চেষ্টা করলে)
    // এটা error না, সফল হিসেবেই ধরা হয়।
    if (err.code === 'auth/user-not-found') {
      alreadyDeleted = true
    } else {
      throw new HttpsError('internal', err.message || 'Failed to delete the Auth account.')
    }
  }

  // Audit log write server-side এ করা হয়, যাতে ব্রাউজার-সাইড কল ব্যর্থ হলেও (network drop,
  // ট্যাব বন্ধ) এই high-risk action-টার লগ এন্ট্রি মিস না হয়। এটা ব্যর্থ হলেও পুরো delete-কে
  // fail করানো হয় না — কাজটা ততক্ষণে সফল হয়ে গেছে — শুধু Cloud Functions log-এ রেকর্ড হয়।
  try {
    await db.collection('adminAuditLog').add({
      action: 'delete_user_data',
      details: { uid: targetUid, customerCount: customersSnap.size, notebookCount: notebooksSnap.size },
      adminUid: callerUid,
      adminEmail: request.auth.token.email || null,
      at: admin.firestore.FieldValue.serverTimestamp(),
    })
  } catch (err) {
    console.error('Failed to write adminAuditLog entry for delete_user_data', targetUid, err)
  }

  return { success: true, customerCount: customersSnap.size, notebookCount: notebooksSnap.size, alreadyDeleted }
})
