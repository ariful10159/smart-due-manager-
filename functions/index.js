const { onCall, HttpsError } = require('firebase-functions/v2/https')
const { onSchedule } = require('firebase-functions/v2/scheduler')
const admin = require('firebase-admin')

admin.initializeApp()

const BATCH_LIMIT = 450

// App Check enforcement — এটা true করার আগে অবশ্যই admin panel এ VITE_RECAPTCHA_SITE_KEY
// সেট করে rebuild+deploy করা থাকতে হবে (দেখুন admin-panel/src/firebase.js এবং
// lib/main.dart এর App Check activation)। নাহলে এটা true করলেই admin panel/app এর
// সব callable function call "App Check token missing" দিয়ে ভেঙে যাবে — client এখনও
// কোনো টোকেন পাঠাচ্ছে না। রোলআউট শেষ হওয়ার পর `firebase functions:config:set` বা
// Cloud Functions env var দিয়ে ENFORCE_APP_CHECK=true সেট করে deploy করলেই enforcement চালু হবে।
const ENFORCE_APP_CHECK = process.env.ENFORCE_APP_CHECK === 'true'

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
exports.deleteUserData = onCall({ timeoutSeconds: 300, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
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
exports.addAdmin = onCall({ enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
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

  // UID টা আসলেই একটা real Firebase Auth user কিনা যাচাই করা — নাহলে টাইপো UID দিয়ে
  // orphaned admin ডকুমেন্ট তৈরি হয়ে যেত (কেউ কখনো লগইনই করতে পারবে না এমন একটা admin গ্রান্ট)।
  try {
    await admin.auth().getUser(targetUid)
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      throw new HttpsError('not-found', 'No Firebase Auth user exists with this UID.')
    }
    throw new HttpsError('internal', err.message || 'Could not verify this UID.')
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
exports.removeAdmin = onCall({ enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
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
exports.setAdminRole = onCall({ enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
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

// Admin panel থেকে টার্গেট গ্রুপ (সব ইউজার / active / নতুন signup) বেছে push পাঠানো —
// শুধু super admin, কারণ ভুল করে সব ইউজারকে একসাথে push পাঠিয়ে ফেলার ঝুঁকি বেশি।
// টোকেন লিস্ট সবসময় server-side এই থাকে (Admin SDK), ব্রাউজারে কখনো যায় না।
exports.sendPushNotification = onCall({ timeoutSeconds: 300, enforceAppCheck: ENFORCE_APP_CHECK }, async (request) => {
  const callerUid = await requireSuperAdmin(request)

  const title = request.data?.title
  const body = request.data?.body
  const targetGroup = request.data?.targetGroup
  const newSignupDays = request.data?.newSignupDays

  if (!title || typeof title !== 'string' || !title.trim()) {
    throw new HttpsError('invalid-argument', 'A title is required.')
  }
  if (!body || typeof body !== 'string' || !body.trim()) {
    throw new HttpsError('invalid-argument', 'A body is required.')
  }
  if (!['all', 'active', 'newSignups'].includes(targetGroup)) {
    throw new HttpsError('invalid-argument', "targetGroup must be 'all', 'active', or 'newSignups'.")
  }
  if (targetGroup === 'newSignups' && (!Number.isInteger(newSignupDays) || newSignupDays < 1 || newSignupDays > 365)) {
    throw new HttpsError('invalid-argument', 'newSignupDays must be an integer between 1 and 365.')
  }

  const db = admin.firestore()

  // টার্গেট গ্রুপ অনুযায়ী candidate uid+token লিস্ট বানানো — 'active' Firestore
  // equality query দিয়ে হয় না কারণ 'disabled' field না থাকা ডকুমেন্ট (বেশিরভাগ
  // ইউজারই) সেই query তে ধরা পড়বে না, তাই in-memory ফিল্টার করা হয় (UsersListPage.jsx
  // client-side এ একই কারণে যা করে)।
  let candidates
  if (targetGroup === 'all') {
    const snap = await db.collection('users').select('fcmToken').get()
    candidates = snap.docs.map((d) => ({ uid: d.id, token: d.data().fcmToken }))
  } else if (targetGroup === 'active') {
    const snap = await db.collection('users').select('fcmToken', 'disabled').get()
    candidates = snap.docs.filter((d) => !d.data().disabled).map((d) => ({ uid: d.id, token: d.data().fcmToken }))
  } else {
    const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - newSignupDays * 86400000)
    const snap = await db.collection('users').where('createdAt', '>=', cutoff).select('fcmToken').get()
    candidates = snap.docs.map((d) => ({ uid: d.id, token: d.data().fcmToken }))
  }

  const targetCount = candidates.length
  const withToken = candidates.filter((c) => !!c.token)
  const skippedNoTokenCount = targetCount - withToken.length

  // FCM sendEachForMulticast এর হার্ড লিমিট প্রতি কলে ৫০০ টোকেন, তাই chunk করে পাঠানো হয়।
  let sentCount = 0
  let failedCount = 0
  const invalidTokenUids = []
  for (let i = 0; i < withToken.length; i += 500) {
    const chunk = withToken.slice(i, i + 500)
    const res = await admin.messaging().sendEachForMulticast({
      tokens: chunk.map((c) => c.token),
      notification: { title, body },
      data: { type: 'admin_push' },
      android: { priority: 'high', notification: { channelId: 'push_channel' } },
    })
    sentCount += res.successCount
    failedCount += res.failureCount
    res.responses.forEach((r, idx) => {
      if (
        !r.success &&
        (r.error?.code === 'messaging/registration-token-not-registered' ||
          r.error?.code === 'messaging/invalid-argument')
      ) {
        invalidTokenUids.push(chunk[idx].uid)
      }
    })
  }

  // পাঠানোর সময় FCM যে টোকেনগুলোকে dead/invalid বলে জানাল (app uninstall/data clear
  // ইত্যাদির কারণে), সেগুলো user doc থেকে সাথে সাথে মুছে দেওয়া — standard FCM hygiene।
  for (let i = 0; i < invalidTokenUids.length; i += BATCH_LIMIT) {
    const batch = db.batch()
    invalidTokenUids
      .slice(i, i + BATCH_LIMIT)
      .forEach((uid) => batch.update(db.collection('users').doc(uid), { fcmToken: admin.firestore.FieldValue.delete() }))
    await batch.commit()
  }

  const counts = { targetCount, sentCount, failedCount, skippedNoTokenCount, invalidTokenCount: invalidTokenUids.length }

  // প্রতিটা টার্গেট ইউজারের জন্য একটা in-app রেকর্ড লেখা হয় (candidates — পুরো টার্গেট
  // গ্রুপ, শুধু যাদের token পাওয়া গেছে তারা না) — যাতে token না থাকা বা notification
  // permission বন্ধ থাকা ইউজারও app-এর Notifications screen খুললে মেসেজটা দেখতে পায়।
  // 'message'/'createdAt' নাম ইচ্ছাকৃতভাবে announcements collection-এর ফিল্ড নামের
  // সাথে মেলানো — lib/screens/notifications_screen.dart দুটো collection-ই একসাথে
  // merge করে একই রেন্ডারিং কোড দিয়ে দেখায়।
  for (let i = 0; i < candidates.length; i += BATCH_LIMIT) {
    const batch = db.batch()
    candidates.slice(i, i + BATCH_LIMIT).forEach((c) => {
      batch.set(db.collection('userNotifications').doc(), {
        recipientUid: c.uid,
        title,
        message: body,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      })
    })
    await batch.commit()
  }

  await db.collection('pushNotifications').add({
    title,
    body,
    targetGroup,
    newSignupDays: newSignupDays || null,
    ...counts,
    sentBy: callerUid,
    sentByEmail: request.auth.token.email,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
  })

  await logAdminAction(db, {
    action: 'send_push_notification',
    details: { targetGroup, newSignupDays: newSignupDays || null, title, ...counts },
    callerUid,
    callerEmail: request.auth.token.email,
  })

  return { success: true, ...counts }
})

// maintenanceUntil পার হয়ে গেলে appConfig/main.maintenanceEnabled নিজে থেকেই false করে
// দেয় — আগে এটা শুধু admin panel-এর AppConfigPage লোড হওয়ার সময় (client-side) হতো,
// তাই কোনো admin panel না খোলা পর্যন্ত dashboard-এ "Maintenance: ON" আটকে থেকে যেত
// (যদিও app নিজে maintenanceUntil ধরে already unblock হয়ে যায় — দেখুন
// lib/widgets/app_config_gate.dart — তাই এটা real user-facing outage না, শুধু stale
// admin-dashboard state)। এখন প্রতি ৩০ মিনিটে independent ভাবে চেক করে।
exports.autoDisableExpiredMaintenance = onSchedule('every 30 minutes', async () => {
  const db = admin.firestore()
  const configRef = db.collection('appConfig').doc('main')
  const snap = await configRef.get()
  if (!snap.exists) return

  const data = snap.data()
  const until = data.maintenanceUntil?.toDate ? data.maintenanceUntil.toDate() : null
  if (!data.maintenanceEnabled || !until || until.getTime() > Date.now()) return

  await configRef.update({ maintenanceEnabled: false, updatedAt: admin.firestore.FieldValue.serverTimestamp() })

  await logAdminAction(db, {
    action: 'auto_disable_expired_maintenance',
    details: { maintenanceUntil: until.toISOString() },
    callerUid: null,
    callerEmail: 'system (scheduled function)',
  })
})
