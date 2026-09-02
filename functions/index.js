const { onCall, HttpsError } = require('firebase-functions/v2/https')
const admin = require('firebase-admin')

admin.initializeApp()

const BATCH_LIMIT = 450

// role field না থাকলে (migration-এর আগের পুরনো admin ডকুমেন্ট) super হিসেবেই ধরা হয় —
// এতে existing admin-দের জন্য আলাদা migration script চালানোর দরকার নেই।
function roleOf(adminDocData) {
  return adminDocData.role === 'staff' ? 'staff' : 'super'
}

async function getCallerAdminInfo(request) {
  const callerUid = request.auth?.uid
  if (!callerUid) {
    throw new HttpsError('unauthenticated', 'Must be signed in.')
  }
  const adminDoc = await admin.firestore().collection('admins').doc(callerUid).get()
  if (!adminDoc.exists) {
    throw new HttpsError('permission-denied', 'Only admins can do this.')
  }
  return { callerUid, role: roleOf(adminDoc.data()) }
}

async function requireSuperAdmin(request) {
  const { callerUid, role } = await getCallerAdminInfo(request)
  if (role !== 'super') {
    throw new HttpsError('permission-denied', 'Only super admins can do this.')
  }
  return callerUid
}

// টার্গেট uid বাদে বাকিদের মধ্যে অন্তত একজন super admin থাকবে কিনা — remove/demote করার
// আগে এই চেকটাই শেষ super admin কে lock-out হওয়া থেকে আটকায়।
async function hasAnotherSuperAdmin(db, excludeUid) {
  const allAdmins = await db.collection('admins').get()
  return allAdmins.docs.some((d) => d.id !== excludeUid && roleOf(d.data()) === 'super')
}

async function logAdminAction(db, { action, details, callerUid, callerEmail }) {
  // Audit log write ব্যর্থ হলেও মূল admin action fail করানো হয় না (কাজটা ততক্ষণে সফল
  // হয়ে গেছে) — শুধু Cloud Functions log-এ রেকর্ড হয়, যাতে failure পুরোপুরি invisible না থাকে।
  try {
    await db.collection('adminAuditLog').add({
      action,
      details,
      adminUid: callerUid,
      adminEmail: callerEmail || null,
      at: admin.firestore.FieldValue.serverTimestamp(),
    })
  } catch (err) {
    console.error(`Failed to write adminAuditLog entry for ${action}`, details, err)
  }
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
// কল করলে বাকি অংশ থেকে চালিয়ে সম্পূর্ণ করা যায় (safe to retry)। শুধু super admin-রাই
// এই সবচেয়ে destructive action চালাতে পারবে।
exports.deleteUserData = onCall({ timeoutSeconds: 300 }, async (request) => {
  const callerUid = await requireSuperAdmin(request)

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

  await logAdminAction(db, {
    action: 'delete_user_data',
    details: { uid: targetUid, customerCount: customersSnap.size, notebookCount: notebooksSnap.size },
    callerUid,
    callerEmail: request.auth.token.email,
  })

  return { success: true, customerCount: customersSnap.size, notebookCount: notebooksSnap.size, alreadyDeleted }
})

// শুধু super admin-রাই admin panel-এ নতুন admin যুক্ত করতে পারবে।
exports.addAdmin = onCall(async (request) => {
  const callerUid = await requireSuperAdmin(request)

  const targetUid = request.data?.uid
  const email = request.data?.email || null
  const role = request.data?.role
  if (!targetUid || typeof targetUid !== 'string') {
    throw new HttpsError('invalid-argument', 'A target uid is required.')
  }
  if (role !== 'super' && role !== 'staff') {
    throw new HttpsError('invalid-argument', "Role must be 'super' or 'staff'.")
  }

  const db = admin.firestore()
  await db.collection('admins').doc(targetUid).set({
    email,
    role,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: callerUid,
  })

  await logAdminAction(db, {
    action: 'add_admin',
    details: { uid: targetUid, email, role },
    callerUid,
    callerEmail: request.auth.token.email,
  })

  return { success: true }
})

// শুধু super admin-রাই admin remove করতে পারবে — এবং শেষ super admin কে remove করা
// block করা হয়, যাতে পুরো টিম admin panel থেকে lock-out না হয়ে যায়।
exports.removeAdmin = onCall(async (request) => {
  const callerUid = await requireSuperAdmin(request)

  const targetUid = request.data?.uid
  if (!targetUid || typeof targetUid !== 'string') {
    throw new HttpsError('invalid-argument', 'A target uid is required.')
  }

  const db = admin.firestore()
  const targetRef = db.collection('admins').doc(targetUid)
  const targetDoc = await targetRef.get()
  if (!targetDoc.exists) {
    return { success: true, alreadyRemoved: true }
  }
  const targetRole = roleOf(targetDoc.data())

  if (targetRole === 'super' && !(await hasAnotherSuperAdmin(db, targetUid))) {
    throw new HttpsError(
      'failed-precondition',
      'Cannot remove the last super admin — promote another admin to super first.',
    )
  }

  await targetRef.delete()

  await logAdminAction(db, {
    action: 'remove_admin',
    details: { uid: targetUid, email: targetDoc.data().email || null, role: targetRole },
    callerUid,
    callerEmail: request.auth.token.email,
  })

  return { success: true }
})

// একজন admin-এর role বদলায় (super <-> staff) — শুধু super admin-রা করতে পারবে, এবং শেষ
// super admin কে staff-এ demote করা block করা হয় (removeAdmin-এর মতোই safeguard)।
exports.setAdminRole = onCall(async (request) => {
  const callerUid = await requireSuperAdmin(request)

  const targetUid = request.data?.uid
  const newRole = request.data?.role
  if (!targetUid || typeof targetUid !== 'string') {
    throw new HttpsError('invalid-argument', 'A target uid is required.')
  }
  if (newRole !== 'super' && newRole !== 'staff') {
    throw new HttpsError('invalid-argument', "Role must be 'super' or 'staff'.")
  }

  const db = admin.firestore()
  const targetRef = db.collection('admins').doc(targetUid)
  const targetDoc = await targetRef.get()
  if (!targetDoc.exists) {
    throw new HttpsError('not-found', 'This admin no longer exists.')
  }
  const currentRole = roleOf(targetDoc.data())
  if (currentRole === newRole) {
    return { success: true, unchanged: true }
  }

  if (currentRole === 'super' && newRole === 'staff' && !(await hasAnotherSuperAdmin(db, targetUid))) {
    throw new HttpsError(
      'failed-precondition',
      'Cannot demote the last super admin — promote another admin to super first.',
    )
  }

  await targetRef.update({ role: newRole })

  await logAdminAction(db, {
    action: 'set_admin_role',
    details: { uid: targetUid, oldRole: currentRole, newRole },
    callerUid,
    callerEmail: request.auth.token.email,
  })

  return { success: true }
})
