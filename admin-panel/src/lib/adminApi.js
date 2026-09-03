import { auth, db, storage, functions } from '../firebase'
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  startAfter,
  updateDoc,
  deleteDoc,
  setDoc,
  addDoc,
  writeBatch,
  serverTimestamp,
} from 'firebase/firestore'
import { ref, getDownloadURL } from 'firebase/storage'
import { httpsCallable } from 'firebase/functions'
import { Sentry } from '../sentry.js'

const BATCH_LIMIT = 450

async function deleteQuerySnapshotInBatches(snapshot) {
  const docs = snapshot.docs
  for (let i = 0; i < docs.length; i += BATCH_LIMIT) {
    const batch = writeBatch(db)
    docs.slice(i, i + BATCH_LIMIT).forEach((d) => batch.delete(d.ref))
    await batch.commit()
  }
}

// ============================================
// Audit log
// ============================================

async function logAction(action, details = {}) {
  try {
    await addDoc(collection(db, 'adminAuditLog'), {
      action,
      details,
      adminUid: auth.currentUser?.uid || null,
      adminEmail: auth.currentUser?.email || null,
      at: serverTimestamp(),
    })
  } catch (err) {
    // Audit logging must never block the actual admin action — but a swallowed failure here
    // means an action happened with zero trace of it, so at least surface it loudly to whoever
    // has devtools open, and report it to Sentry so it's visible even with no one watching.
    console.error(`[audit log] failed to record "${action}" — the admin action itself still succeeded`, details, err)
    Sentry.captureException(err, { extra: { context: 'audit log write failed', action, details } })
  }
}

export const AUDIT_LOG_PAGE_SIZE = 50

// Cursor-based paging (ordered by 'at' desc) instead of a flat cap — pass the last-loaded
// item's 'at' timestamp as `after` to fetch the next page. Returns up to AUDIT_LOG_PAGE_SIZE
// items; getting back fewer than that means there's nothing more to load.
export async function fetchAuditLog(after) {
  const constraints = [collection(db, 'adminAuditLog'), orderBy('at', 'desc')]
  if (after) constraints.push(startAfter(after))
  constraints.push(limit(AUDIT_LOG_PAGE_SIZE))
  const snap = await getDocs(query(...constraints))
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

// Regular shopkeeper activity (customer/payment add-edit-delete etc.), written directly
// from the Flutter app — see lib/services/activity_log_service.dart. Same cursor pattern.
export async function fetchUserActivityLog(after) {
  const constraints = [collection(db, 'userActivityLog'), orderBy('at', 'desc')]
  if (after) constraints.push(startAfter(after))
  constraints.push(limit(AUDIT_LOG_PAGE_SIZE))
  const snap = await getDocs(query(...constraints))
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

// ============================================
// Users
// ============================================

export async function fetchUsers() {
  const snap = await getDocs(collection(db, 'users'))
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

export async function fetchUser(uid) {
  const snap = await getDoc(doc(db, 'users', uid))
  return snap.exists() ? { id: snap.id, ...snap.data() } : null
}

export async function toggleUserDisabled(uid, disabled) {
  await updateDoc(doc(db, 'users', uid), { disabled })
  await logAction(disabled ? 'disable_user' : 'enable_user', { uid })
}

export async function resetUserPin(uid) {
  await updateDoc(doc(db, 'users', uid), {
    'settings.appLockPinHash': null,
    'settings.appLockEnabled': false,
  })
  await logAction('reset_pin', { uid })
}

// Runs entirely server-side (Cloud Function, Admin SDK) so it keeps going — and finishes —
// even if this browser tab is closed mid-delete. It's also safe to call again on a user whose
// deletion previously got interrupted: already-deleted documents just won't be found the
// second time, so a retry picks up wherever the first attempt left off.
export async function deleteUserDataCascade(uid) {
  try {
    const result = await httpsCallable(functions, 'deleteUserData')({ uid })
    return result.data
  } catch (e) {
    await logAction('delete_user_data_failed', { uid, error: e.message || String(e) })
    throw new Error(e.message || 'Failed to delete this user.')
  }
}

export async function getBusinessLogoUrl(uid) {
  try {
    return await getDownloadURL(ref(storage, `business_logos/${uid}.jpg`))
  } catch {
    return null
  }
}

// ============================================
// Customers
// ============================================

export async function fetchUserCustomers(uid) {
  const q = query(collection(db, 'customers'), where('ownerId', '==', uid))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

export async function fetchAllCustomers() {
  const snap = await getDocs(collection(db, 'customers'))
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

export async function updateCustomer(customerId, data) {
  await updateDoc(doc(db, 'customers', customerId), data)
  await logAction('update_customer', { customerId })
}

export async function deleteCustomer(customerId) {
  for (const sub of ['payments', 'reminders', 'smsLogs']) {
    const snap = await getDocs(collection(db, 'customers', customerId, sub))
    await deleteQuerySnapshotInBatches(snap)
  }
  await deleteDoc(doc(db, 'customers', customerId))
  await logAction('delete_customer', { customerId })
}

// ============================================
// Payments
// ============================================

export async function fetchCustomerPayments(customerId) {
  const q = query(collection(db, 'customers', customerId, 'payments'), orderBy('date', 'desc'))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

// Fetches every payment across the given customers (one query per customer, run in parallel).
// Fine at admin-tool scale; revisit with a collectionGroup query if this ever needs to handle
// thousands of customers.
export async function fetchAllPayments(customerIds) {
  const snapshots = await Promise.all(
    customerIds.map((id) => getDocs(collection(db, 'customers', id, 'payments'))),
  )
  return snapshots.flatMap((snap) => snap.docs.map((d) => ({ id: d.id, ...d.data() })))
}

export async function updatePayment(customerId, paymentId, data) {
  await updateDoc(doc(db, 'customers', customerId, 'payments', paymentId), data)
  await logAction('update_payment', { customerId, paymentId })
}

export async function deletePayment(customerId, paymentId) {
  await deleteDoc(doc(db, 'customers', customerId, 'payments', paymentId))
  await logAction('delete_payment', { customerId, paymentId })
}

// ============================================
// Reminders & SMS logs (read-only in admin panel)
// ============================================

export async function fetchCustomerReminders(customerId) {
  const q = query(collection(db, 'customers', customerId, 'reminders'), orderBy('createdAt', 'desc'))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

export async function fetchCustomerSmsLogs(customerId) {
  const q = query(collection(db, 'customers', customerId, 'smsLogs'), orderBy('sentAt', 'desc'))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

// ============================================
// Notebooks
// ============================================

export async function fetchAllNotebooks() {
  const snap = await getDocs(collection(db, 'notebooks'))
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

export async function fetchUserNotebooks(uid) {
  const q = query(collection(db, 'notebooks'), where('ownerId', '==', uid))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

export async function fetchNotebookPages(notebookId) {
  const q = query(collection(db, 'notebooks', notebookId, 'pages'), orderBy('order', 'asc'))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

export async function deleteNotebook(notebookId) {
  const pagesSnap = await getDocs(collection(db, 'notebooks', notebookId, 'pages'))
  await deleteQuerySnapshotInBatches(pagesSnap)
  await deleteDoc(doc(db, 'notebooks', notebookId))
  await logAction('delete_notebook', { notebookId })
}

// Quill delta JSON -> plain text preview.
export function quillDeltaToText(contentJson) {
  try {
    const ops = JSON.parse(contentJson)
    return ops.map((op) => (typeof op.insert === 'string' ? op.insert : '')).join('')
  } catch {
    return ''
  }
}

// ============================================
// Announcements
// ============================================

export async function fetchAnnouncements() {
  const q = query(collection(db, 'announcements'), orderBy('updatedAt', 'desc'))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

export async function createAnnouncement(data) {
  const ref = await addDoc(collection(db, 'announcements'), {
    ...data,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  })
  await logAction('create_announcement', { id: ref.id, title: data.title })
  return ref.id
}

export async function updateAnnouncement(id, data) {
  await updateDoc(doc(db, 'announcements', id), { ...data, updatedAt: serverTimestamp() })
  await logAction('update_announcement', { id, title: data.title })
}

export async function deleteAnnouncement(id) {
  await deleteDoc(doc(db, 'announcements', id))
  await logAction('delete_announcement', { id })
}

// Popup images are stored inline as a base64 data URI on the announcement doc itself
// (no Firebase Storage involved) — keeps this working without any extra rules deploy.
// Firestore caps a document at 1MiB total, and base64 inflates size by ~33%, so
// whatever the admin picks gets client-side compressed (downscale + re-encode as
// JPEG, trying progressively smaller until it fits) rather than rejected.
export const MAX_ANNOUNCEMENT_IMAGE_BYTES = 500 * 1024 // target after compression
const DIMENSION_STEPS = [1600, 1280, 1024, 800, 600, 480]
const QUALITY_STEPS = [0.85, 0.7, 0.55, 0.4, 0.3]

function loadImageElement(objectUrl) {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => resolve(img)
    img.onerror = () => reject(new Error('Could not read this image file.'))
    img.src = objectUrl
  })
}

export function dataUrlByteSize(dataUrl) {
  const base64 = dataUrl.split(',')[1] || ''
  return Math.ceil((base64.length * 3) / 4)
}

export async function compressImageToDataUrl(file, maxBytes = MAX_ANNOUNCEMENT_IMAGE_BYTES) {
  const objectUrl = URL.createObjectURL(file)
  try {
    const img = await loadImageElement(objectUrl)
    const naturalWidth = img.naturalWidth || img.width
    const naturalHeight = img.naturalHeight || img.height

    let lastAttempt = null
    for (const maxDim of DIMENSION_STEPS) {
      const scale = Math.min(1, maxDim / Math.max(naturalWidth, naturalHeight))
      const width = Math.max(1, Math.round(naturalWidth * scale))
      const height = Math.max(1, Math.round(naturalHeight * scale))

      const canvas = document.createElement('canvas')
      canvas.width = width
      canvas.height = height
      canvas.getContext('2d').drawImage(img, 0, 0, width, height)

      for (const quality of QUALITY_STEPS) {
        const dataUrl = canvas.toDataURL('image/jpeg', quality)
        lastAttempt = dataUrl
        if (dataUrlByteSize(dataUrl) <= maxBytes) return dataUrl
      }
    }
    // Smallest/lowest-quality attempt didn't fit — return it anyway, it's the best we can do.
    return lastAttempt
  } finally {
    URL.revokeObjectURL(objectUrl)
  }
}

// ============================================
// Problem reports (user-submitted, from Report a Problem in the app)
// ============================================

export async function fetchProblemReports() {
  const q = query(collection(db, 'problemReports'), orderBy('createdAt', 'desc'), limit(200))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

export async function updateProblemReportStatus(id, status) {
  await updateDoc(doc(db, 'problemReports', id), { status, updatedAt: serverTimestamp() })
  await logAction('update_problem_report_status', { id, status })
}

// priority: 'low' | 'medium' | 'high' — internal triage field, admin-only, not shown to the
// reporting user.
export async function updateProblemReportPriority(id, priority) {
  await updateDoc(doc(db, 'problemReports', id), { priority, updatedAt: serverTimestamp() })
  await logAction('update_problem_report_priority', { id, priority })
}

// Internal note — visible only in this admin panel, never shown to the reporting user.
export async function updateProblemReportNotes(id, adminNotes) {
  await updateDoc(doc(db, 'problemReports', id), { adminNotes, updatedAt: serverTimestamp() })
  await logAction('update_problem_report_notes', { id })
}

// Stored on the report so the reply is on record — the Flutter app doesn't yet have a
// screen that surfaces this back to the reporting user, so for now this is an internal
// record of what was told to the user (e.g. over phone/SMS), not an in-app notification.
export async function replyToProblemReport(id, reply) {
  await updateDoc(doc(db, 'problemReports', id), {
    adminReply: reply,
    adminReplyAt: serverTimestamp(),
    adminReplyBy: auth.currentUser?.email || null,
    updatedAt: serverTimestamp(),
  })
  await logAction('reply_to_problem_report', { id })
}

// ============================================
// Admins
// ============================================

export async function fetchAdmins() {
  const snap = await getDocs(collection(db, 'admins'))
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

// role: 'super' | 'staff'. Runs server-side (Cloud Function) — only super admins may call
// it, and the function itself re-verifies that rather than trusting the client.
export async function addAdmin(uid, email, role) {
  await httpsCallable(functions, 'addAdmin')({ uid, email: email || null, role })
}

// Server-side (Cloud Function) blocks removing the last remaining super admin, so the whole
// team can't get locked out of the panel.
export async function removeAdmin(uid) {
  await httpsCallable(functions, 'removeAdmin')({ uid })
}

// role: 'super' | 'staff'. Same last-super-admin protection as removeAdmin applies to demotion.
export async function setAdminRole(uid, role) {
  await httpsCallable(functions, 'setAdminRole')({ uid, role })
}

// ============================================
// App Config
// ============================================

const APP_CONFIG_DOC = doc(db, 'appConfig', 'main')

export async function fetchAppConfig() {
  const snap = await getDoc(APP_CONFIG_DOC)
  return snap.exists() ? snap.data() : {}
}

// Generic partial update for cards that don't need their own history log
// (Maintenance Mode, Force Update toggle, About App, Contact).
export async function updateAppConfig(data, actionName) {
  await setDoc(APP_CONFIG_DOC, { ...data, updatedAt: serverTimestamp() }, { merge: true })
  await logAction(actionName || 'update_app_config', data)
}

export async function fetchVersionHistory() {
  const q = query(collection(db, 'appConfig', 'main', 'versionHistory'), orderBy('changedAt', 'desc'), limit(50))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

// Rejects a no-op save (identical currentVersion) so the history log doesn't fill up
// with duplicate entries.
export async function publishVersion({ currentVersion, minRequiredVersion, playStoreUrl }) {
  const existing = await fetchAppConfig()
  if (existing.currentVersion === currentVersion) {
    throw new Error('This is already the current version — change it before saving.')
  }
  await setDoc(
    APP_CONFIG_DOC,
    { currentVersion, minRequiredVersion, playStoreUrl: playStoreUrl || null, updatedAt: serverTimestamp() },
    { merge: true },
  )
  await addDoc(collection(db, 'appConfig', 'main', 'versionHistory'), {
    currentVersion,
    minRequiredVersion,
    changedBy: auth.currentUser?.email || null,
    changedAt: serverTimestamp(),
  })
  await logAction('publish_version', { currentVersion, minRequiredVersion })
}

// Each policy type gets its own history subcollection (privacyHistory / termsHistory)
// rather than one shared subcollection filtered by a `type` field — avoids needing a
// composite Firestore index for the equality-filter-plus-orderBy query.
export async function fetchPolicyHistory(type) {
  const q = query(collection(db, 'appConfig', 'main', `${type}History`), orderBy('publishedAt', 'desc'), limit(20))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

// type: 'privacy' | 'terms'
export async function publishPolicy(type, { textEn, textBn }) {
  const existing = await fetchAppConfig()
  const nextVersion = (existing[`${type}Version`] || 0) + 1
  await setDoc(
    APP_CONFIG_DOC,
    {
      [`${type}En`]: textEn,
      [`${type}Bn`]: textBn,
      [`${type}Version`]: nextVersion,
      [`${type}PublishedAt`]: serverTimestamp(),
      updatedAt: serverTimestamp(),
    },
    { merge: true },
  )
  await addDoc(collection(db, 'appConfig', 'main', `${type}History`), {
    textEn,
    textBn,
    version: nextVersion,
    publishedBy: auth.currentUser?.email || null,
    publishedAt: serverTimestamp(),
  })
  await logAction('publish_policy', { type, version: nextVersion })
}

// ============================================
// Push notifications
// ============================================

// targetGroup: 'all' | 'active' | 'newSignups'. newSignupDays only used (and required)
// for 'newSignups'. Runs server-side (Cloud Function, Admin SDK) — the fcmToken list
// never touches the browser, and the function itself re-checks super-admin, same as
// addAdmin. It also writes its own history doc + adminAuditLog entry, so no client-side
// logAction call here (would just duplicate the audit trail).
export async function sendPushNotification({ title, body, targetGroup, newSignupDays }) {
  const result = await httpsCallable(functions, 'sendPushNotification')({
    title,
    body,
    targetGroup,
    newSignupDays: newSignupDays || null,
  })
  return result.data
}

export async function fetchPushNotifications() {
  const q = query(collection(db, 'pushNotifications'), orderBy('sentAt', 'desc'), limit(50))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

// ============================================
// FAQ
// ============================================

export async function fetchFaqs() {
  const q = query(collection(db, 'faqs'), orderBy('order', 'asc'))
  const snap = await getDocs(q)
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

export async function addFaq(data) {
  const ref = await addDoc(collection(db, 'faqs'), {
    ...data,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  })
  await logAction('add_faq', { id: ref.id, question: data.question })
  return ref.id
}

export async function updateFaq(id, data) {
  await updateDoc(doc(db, 'faqs', id), { ...data, updatedAt: serverTimestamp() })
  await logAction('update_faq', { id, question: data.question })
}

export async function deleteFaq(id) {
  await deleteDoc(doc(db, 'faqs', id))
  await logAction('delete_faq', { id })
}

// Bulk import (Excel) — chunked into atomic batches (each chunk all-or-nothing) instead of
// one addDoc per row, so a failure partway through doesn't leave a half-imported mess for
// typical import sizes (well under BATCH_LIMIT rows).
export async function addFaqsBatch(rows) {
  for (let i = 0; i < rows.length; i += BATCH_LIMIT) {
    const chunk = rows.slice(i, i + BATCH_LIMIT)
    const batch = writeBatch(db)
    for (const row of chunk) {
      batch.set(doc(collection(db, 'faqs')), {
        ...row,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      })
    }
    await batch.commit()
  }
  await logAction('bulk_add_faq', { count: rows.length })
}
