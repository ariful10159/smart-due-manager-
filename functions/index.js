const { onCall, HttpsError } = require('firebase-functions/v2/https')
const admin = require('firebase-admin')

admin.initializeApp()

// Firebase Auth এ অন্য কোনো user এর account delete করার একমাত্র উপায় হলো Admin SDK —
// এটা client-side (admin panel browser) থেকে করা সম্ভব না, Firebase নিজেই সেটা ব্লক করে
// রাখে। তাই এই callable Cloud Function টা লাগে। শুধু admins/{uid} কালেকশনে থাকা admin-রাই
// এটা কল করতে পারবে — server-side এ যাচাই করা হয়, client এর isAdmin দাবির উপর ভরসা করা হয় না।
//
// Firestore এর ডেটা (customers, notebooks, users/{uid} ডকুমেন্ট) আগেই client থেকে
// deleteUserDataCascade() দিয়ে মোছা হয় (admin-panel/src/lib/adminApi.js) — এই function
// শুধু বাকি থাকা Auth account (ফোন নাম্বার + পাসওয়ার্ড) মুছে।
exports.deleteUserAuth = onCall(async (request) => {
  const callerUid = request.auth?.uid
  if (!callerUid) {
    throw new HttpsError('unauthenticated', 'Must be signed in.')
  }

  const adminDoc = await admin.firestore().collection('admins').doc(callerUid).get()
  if (!adminDoc.exists) {
    throw new HttpsError('permission-denied', 'Only admins can delete user accounts.')
  }

  const targetUid = request.data?.uid
  if (!targetUid || typeof targetUid !== 'string') {
    throw new HttpsError('invalid-argument', 'A target uid is required.')
  }

  try {
    await admin.auth().deleteUser(targetUid)
  } catch (err) {
    // ইতিমধ্যে Auth থেকে ডিলিট হয়ে গেলে (যেমন partial failure এর পর আবার চেষ্টা করলে)
    // এটা error না, সফল হিসেবেই ধরা হয়।
    if (err.code === 'auth/user-not-found') {
      return { success: true, alreadyDeleted: true }
    }
    throw new HttpsError('internal', err.message || 'Failed to delete the Auth account.')
  }

  return { success: true }
})
