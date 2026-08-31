import { auth, db, storage } from '../firebase'
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  updateDoc,
  deleteDoc,
  setDoc,
  addDoc,
  writeBatch,
  serverTimestamp,
} from 'firebase/firestore'
import { ref, getDownloadURL } from 'firebase/storage'

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
  } catch {
    // Audit logging must never block the actual admin action.
  }
}

export async function fetchAuditLog() {
  const q = query(collection(db, 'adminAuditLog'), orderBy('at', 'desc'), limit(200))
  const snap = await getDocs(q)
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

export async function deleteUserDataCascade(uid) {
  const customersSnap = await getDocs(query(collection(db, 'customers'), where('ownerId', '==', uid)))
  for (const customerDoc of customersSnap.docs) {
    for (const sub of ['payments', 'reminders', 'smsLogs']) {
      const subSnap = await getDocs(collection(db, 'customers', customerDoc.id, sub))
      await deleteQuerySnapshotInBatches(subSnap)
    }
  }
  await deleteQuerySnapshotInBatches(customersSnap)

  const notebooksSnap = await getDocs(query(collection(db, 'notebooks'), where('ownerId', '==', uid)))
  for (const notebookDoc of notebooksSnap.docs) {
    const pagesSnap = await getDocs(collection(db, 'notebooks', notebookDoc.id, 'pages'))
    await deleteQuerySnapshotInBatches(pagesSnap)
  }
  await deleteQuerySnapshotInBatches(notebooksSnap)

  await deleteDoc(doc(db, 'users', uid))
  await logAction('delete_user_data', { uid, customerCount: customersSnap.size, notebookCount: notebooksSnap.size })
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

// ============================================
// Admins
// ============================================

export async function fetchAdmins() {
  const snap = await getDocs(collection(db, 'admins'))
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }))
}

export async function addAdmin(uid, email) {
  await setDoc(doc(db, 'admins', uid), { email: email || null, createdAt: serverTimestamp() })
  await logAction('add_admin', { uid, email })
}

export async function removeAdmin(uid) {
  await deleteDoc(doc(db, 'admins', uid))
  await logAction('remove_admin', { uid })
}
