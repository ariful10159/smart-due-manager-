import { useEffect, useMemo, useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import {
  fetchUser,
  fetchUserCustomers,
  fetchCustomerPayments,
  fetchCustomerReminders,
  fetchCustomerSmsLogs,
  fetchAllPayments,
  fetchUserNotebooks,
  fetchNotebookPages,
  deleteNotebook,
  quillDeltaToText,
  getBusinessLogoUrl,
  updateCustomer,
  deleteCustomer,
  updatePayment,
  deletePayment,
  toggleUserDisabled,
  resetUserPin,
  deleteUserDataCascade,
} from '../lib/adminApi'
import ConfirmDialog from '../components/ConfirmDialog'
import { toCsv, downloadCsv } from '../lib/csv'

const currency = (n) => `৳${Math.round(n || 0).toLocaleString('en-US')}`

function fmtDate(ts) {
  if (!ts) return '—'
  const d = ts.toDate ? ts.toDate() : new Date(ts)
  return d.toLocaleDateString()
}

const inputClass =
  'w-full rounded-lg border border-ink-700 bg-ink-850 px-3 py-2 text-sm text-white placeholder:text-ink-400 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500'

function ModalShell({ title, children }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm animate-fadeIn">
      <div className="w-full max-w-sm rounded-2xl border border-ink-700 bg-ink-850 p-5 shadow-card">
        <h3 className="text-base font-semibold text-white">{title}</h3>
        {children}
      </div>
    </div>
  )
}

function CustomerEditModal({ customer, onClose, onSave }) {
  const [name, setName] = useState(customer.name || '')
  const [phone, setPhone] = useState(customer.phone || '')
  const [address, setAddress] = useState(customer.address || '')
  const [totalDue, setTotalDue] = useState(customer.totalDue ?? 0)
  const [saving, setSaving] = useState(false)

  const handleSave = async () => {
    setSaving(true)
    await onSave({ name, phone, address, totalDue: Number(totalDue) })
    setSaving(false)
  }

  return (
    <ModalShell title="Edit customer">
      <div className="mt-4 space-y-3">
        <input className={inputClass} value={name} onChange={(e) => setName(e.target.value)} placeholder="Name" />
        <input className={inputClass} value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="Phone" />
        <input
          className={inputClass}
          value={address}
          onChange={(e) => setAddress(e.target.value)}
          placeholder="Address"
        />
        <input
          type="number"
          className={inputClass}
          value={totalDue}
          onChange={(e) => setTotalDue(e.target.value)}
          placeholder="Total due"
        />
      </div>
      <div className="mt-5 flex justify-end gap-2">
        <button
          onClick={onClose}
          className="rounded-lg px-3 py-1.5 text-sm font-medium text-ink-300 transition-colors hover:bg-ink-700 hover:text-white"
        >
          Cancel
        </button>
        <button
          onClick={handleSave}
          disabled={saving}
          className="rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-3 py-1.5 text-sm font-medium text-white shadow-glow transition-transform hover:scale-[1.03] disabled:opacity-60 disabled:hover:scale-100"
        >
          {saving ? 'Saving…' : 'Save'}
        </button>
      </div>
    </ModalShell>
  )
}

function PaymentEditModal({ payment, onClose, onSave }) {
  const [amount, setAmount] = useState(payment.amount ?? 0)
  const [discount, setDiscount] = useState(payment.discount ?? 0)
  const [note, setNote] = useState(payment.note || '')
  const [saving, setSaving] = useState(false)

  const handleSave = async () => {
    setSaving(true)
    await onSave({ amount: Number(amount), discount: Number(discount), note })
    setSaving(false)
  }

  return (
    <ModalShell title="Edit payment">
      <div className="mt-4 space-y-3">
        <input
          type="number"
          className={inputClass}
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="Amount"
        />
        <input
          type="number"
          className={inputClass}
          value={discount}
          onChange={(e) => setDiscount(e.target.value)}
          placeholder="Discount"
        />
        <input className={inputClass} value={note} onChange={(e) => setNote(e.target.value)} placeholder="Note" />
      </div>
      <div className="mt-5 flex justify-end gap-2">
        <button
          onClick={onClose}
          className="rounded-lg px-3 py-1.5 text-sm font-medium text-ink-300 transition-colors hover:bg-ink-700 hover:text-white"
        >
          Cancel
        </button>
        <button
          onClick={handleSave}
          disabled={saving}
          className="rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-3 py-1.5 text-sm font-medium text-white shadow-glow transition-transform hover:scale-[1.03] disabled:opacity-60 disabled:hover:scale-100"
        >
          {saving ? 'Saving…' : 'Save'}
        </button>
      </div>
    </ModalShell>
  )
}

function CustomerRow({ customer, onChanged }) {
  const [expanded, setExpanded] = useState(false)
  const [tab, setTab] = useState('payments')
  const [payments, setPayments] = useState([])
  const [reminders, setReminders] = useState([])
  const [smsLogs, setSmsLogs] = useState([])
  const [detailsLoaded, setDetailsLoaded] = useState(false)
  const [editingCustomer, setEditingCustomer] = useState(false)
  const [editingPayment, setEditingPayment] = useState(null)
  const [confirmDeleteCustomer, setConfirmDeleteCustomer] = useState(false)
  const [confirmDeletePayment, setConfirmDeletePayment] = useState(null)

  const toggleExpand = async () => {
    if (!expanded && !detailsLoaded) {
      const [p, r, s] = await Promise.all([
        fetchCustomerPayments(customer.id),
        fetchCustomerReminders(customer.id),
        fetchCustomerSmsLogs(customer.id),
      ])
      setPayments(p)
      setReminders(r)
      setSmsLogs(s)
      setDetailsLoaded(true)
    }
    setExpanded((v) => !v)
  }

  const refreshPayments = async () => {
    const data = await fetchCustomerPayments(customer.id)
    setPayments(data)
  }

  return (
    <>
      <tr className="transition-colors hover:bg-ink-800/60">
        <td className="px-4 py-3">
          <button onClick={toggleExpand} className="font-medium text-white transition-colors hover:text-indigo-300">
            <span
              className="mr-1.5 inline-block text-indigo-400 transition-transform"
              style={{ transform: expanded ? 'rotate(90deg)' : 'none' }}
            >
              ▸
            </span>
            {customer.name}
          </button>
        </td>
        <td className="px-4 py-3 text-ink-300">{customer.phone}</td>
        <td className="px-4 py-3 text-ink-200">{currency(customer.totalDue)}</td>
        <td className="px-4 py-3 text-ink-400">{fmtDate(customer.createdAt)}</td>
        <td className="px-4 py-3 text-right">
          <button
            onClick={() => setEditingCustomer(true)}
            className="mr-3 text-sm font-medium text-indigo-400 transition-colors hover:text-indigo-300"
          >
            Edit
          </button>
          <button
            onClick={() => setConfirmDeleteCustomer(true)}
            className="text-sm font-medium text-red-400 transition-colors hover:text-red-300"
          >
            Delete
          </button>
        </td>
      </tr>
      {expanded && (
        <tr>
          <td colSpan={5} className="bg-ink-950/60 px-6 py-4">
            <div className="mb-3 flex gap-1">
              {[
                { key: 'payments', label: `Payments (${payments.length})` },
                { key: 'reminders', label: `Reminders (${reminders.length})` },
                { key: 'sms', label: `SMS log (${smsLogs.length})` },
              ].map((t) => (
                <button
                  key={t.key}
                  onClick={() => setTab(t.key)}
                  className={`rounded-full px-3 py-1 text-xs font-medium transition-colors ${
                    tab === t.key ? 'bg-indigo-500/20 text-indigo-300' : 'text-ink-400 hover:text-ink-200'
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </div>

            <div className="overflow-x-auto">
            {tab === 'payments' &&
              (payments.length === 0 ? (
                <p className="text-sm text-ink-500">No payments.</p>
              ) : (
                <table className="min-w-full text-sm">
                  <thead>
                    <tr className="text-left text-ink-500">
                      <th className="py-1.5 pr-4 font-medium">Type</th>
                      <th className="py-1.5 pr-4 font-medium">Amount</th>
                      <th className="py-1.5 pr-4 font-medium">Method</th>
                      <th className="py-1.5 pr-4 font-medium">Date</th>
                      <th className="py-1.5 pr-4 font-medium">Note</th>
                      <th className="py-1.5"></th>
                    </tr>
                  </thead>
                  <tbody>
                    {payments.map((p) => (
                      <tr key={p.id} className="border-t border-ink-800">
                        <td className="py-2 pr-4 text-ink-200">{p.type}</td>
                        <td className="py-2 pr-4 text-ink-200">{currency(p.amount)}</td>
                        <td className="py-2 pr-4 text-ink-300">{p.paymentMethod || '—'}</td>
                        <td className="py-2 pr-4 text-ink-400">{fmtDate(p.date)}</td>
                        <td className="py-2 pr-4 text-ink-300">{p.note || '—'}</td>
                        <td className="py-2 text-right">
                          <button
                            onClick={() => setEditingPayment(p)}
                            className="mr-3 font-medium text-indigo-400 transition-colors hover:text-indigo-300"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => setConfirmDeletePayment(p)}
                            className="font-medium text-red-400 transition-colors hover:text-red-300"
                          >
                            Delete
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ))}

            {tab === 'reminders' &&
              (reminders.length === 0 ? (
                <p className="text-sm text-ink-500">No reminders.</p>
              ) : (
                <table className="min-w-full text-sm">
                  <thead>
                    <tr className="text-left text-ink-500">
                      <th className="py-1.5 pr-4 font-medium">Status</th>
                      <th className="py-1.5 pr-4 font-medium">Reminder date</th>
                      <th className="py-1.5 pr-4 font-medium">Created</th>
                      <th className="py-1.5 pr-4 font-medium">Note</th>
                    </tr>
                  </thead>
                  <tbody>
                    {reminders.map((r) => (
                      <tr key={r.id} className="border-t border-ink-800">
                        <td className="py-2 pr-4">
                          <span
                            className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                              r.status === 'active'
                                ? 'bg-emerald-500/10 text-emerald-400'
                                : 'bg-ink-700 text-ink-300'
                            }`}
                          >
                            {r.status}
                          </span>
                        </td>
                        <td className="py-2 pr-4 text-ink-200">{fmtDate(r.reminderDate)}</td>
                        <td className="py-2 pr-4 text-ink-400">{fmtDate(r.createdAt)}</td>
                        <td className="py-2 pr-4 text-ink-300">{r.note || '—'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ))}

            {tab === 'sms' &&
              (smsLogs.length === 0 ? (
                <p className="text-sm text-ink-500">No SMS sent.</p>
              ) : (
                <table className="min-w-full text-sm">
                  <thead>
                    <tr className="text-left text-ink-500">
                      <th className="py-1.5 pr-4 font-medium">Type</th>
                      <th className="py-1.5 pr-4 font-medium">Sent at</th>
                    </tr>
                  </thead>
                  <tbody>
                    {smsLogs.map((s) => (
                      <tr key={s.id} className="border-t border-ink-800">
                        <td className="py-2 pr-4 text-ink-200">{s.type}</td>
                        <td className="py-2 pr-4 text-ink-400">{fmtDate(s.sentAt)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ))}
            </div>
          </td>
        </tr>
      )}

      {editingCustomer && (
        <CustomerEditModal
          customer={customer}
          onClose={() => setEditingCustomer(false)}
          onSave={async (data) => {
            await updateCustomer(customer.id, data)
            setEditingCustomer(false)
            onChanged()
          }}
        />
      )}

      {editingPayment && (
        <PaymentEditModal
          payment={editingPayment}
          onClose={() => setEditingPayment(null)}
          onSave={async (data) => {
            await updatePayment(customer.id, editingPayment.id, data)
            setEditingPayment(null)
            await refreshPayments()
          }}
        />
      )}

      <ConfirmDialog
        open={confirmDeleteCustomer}
        title="Delete customer?"
        message={`This deletes ${customer.name} and all their payments/reminders permanently.`}
        confirmLabel="Delete"
        onCancel={() => setConfirmDeleteCustomer(false)}
        onConfirm={async () => {
          await deleteCustomer(customer.id)
          setConfirmDeleteCustomer(false)
          onChanged()
        }}
      />

      <ConfirmDialog
        open={!!confirmDeletePayment}
        title="Delete payment?"
        message="This permanently deletes this payment entry."
        confirmLabel="Delete"
        onCancel={() => setConfirmDeletePayment(null)}
        onConfirm={async () => {
          await deletePayment(customer.id, confirmDeletePayment.id)
          setConfirmDeletePayment(null)
          await refreshPayments()
        }}
      />
    </>
  )
}

function NotebookDetailModal({ notebook, onClose, onDeleted }) {
  const [pages, setPages] = useState([])
  const [loading, setLoading] = useState(true)
  const [confirmDelete, setConfirmDelete] = useState(false)

  useEffect(() => {
    fetchNotebookPages(notebook.id).then((p) => {
      setPages(p)
      setLoading(false)
    })
  }, [notebook.id])

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm animate-fadeIn">
      <div className="max-h-[80vh] w-full max-w-lg overflow-y-auto rounded-2xl border border-ink-700 bg-ink-850 p-5 shadow-card">
        <div className="flex items-start justify-between gap-3">
          <div>
            <h3 className="text-base font-semibold text-white">{notebook.title || 'Untitled'}</h3>
            {notebook.description && <p className="mt-1 text-sm text-ink-400">{notebook.description}</p>}
          </div>
          <button
            onClick={() => setConfirmDelete(true)}
            className="shrink-0 text-sm font-medium text-red-400 transition-colors hover:text-red-300"
          >
            Delete notebook
          </button>
        </div>

        <div className="mt-4 space-y-3">
          {loading ? (
            <div className="flex h-16 items-center justify-center">
              <div className="h-5 w-5 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
            </div>
          ) : pages.length === 0 ? (
            <p className="text-sm text-ink-500">No pages.</p>
          ) : (
            pages.map((page) => (
              <div key={page.id} className="rounded-lg border border-ink-700 bg-ink-900/60 p-3">
                <p className="text-sm font-medium text-white">{page.title || 'Untitled page'}</p>
                <p className="mt-1 line-clamp-3 text-xs text-ink-400">
                  {quillDeltaToText(page.contentJson || page.content) || '(empty)'}
                </p>
              </div>
            ))
          )}
        </div>

        <div className="mt-5 flex justify-end">
          <button
            onClick={onClose}
            className="rounded-lg px-3 py-1.5 text-sm font-medium text-ink-300 transition-colors hover:bg-ink-700 hover:text-white"
          >
            Close
          </button>
        </div>
      </div>

      <ConfirmDialog
        open={confirmDelete}
        title="Delete this notebook?"
        message={`"${notebook.title || 'Untitled'}" and all its pages will be permanently deleted.`}
        confirmLabel="Delete"
        onCancel={() => setConfirmDelete(false)}
        onConfirm={async () => {
          await deleteNotebook(notebook.id)
          setConfirmDelete(false)
          onDeleted()
        }}
      />
    </div>
  )
}

const PAGE_SIZE = 20
const SORT_OPTIONS = [
  { value: 'due_desc', label: 'Highest due' },
  { value: 'name_asc', label: 'Name (A–Z)' },
  { value: 'created_desc', label: 'Newest first' },
  { value: 'created_asc', label: 'Oldest first' },
]

function StatPill({ label, value, accent }) {
  return (
    <div className="rounded-xl border border-ink-800 bg-ink-900/60 px-4 py-3">
      <p className="text-xs font-medium uppercase tracking-wide text-ink-400">{label}</p>
      <p className={`mt-1 text-lg font-semibold ${accent || 'text-white'}`}>{value}</p>
    </div>
  )
}

export default function UserDetailPage() {
  const { uid } = useParams()
  const navigate = useNavigate()
  const [user, setUser] = useState(null)
  const [customers, setCustomers] = useState([])
  const [loading, setLoading] = useState(true)
  const [payments, setPayments] = useState([])
  const [notebooks, setNotebooks] = useState([])
  const [statsLoading, setStatsLoading] = useState(true)
  const [confirmDisable, setConfirmDisable] = useState(false)
  const [confirmDeleteAll, setConfirmDeleteAll] = useState(false)
  const [busy, setBusy] = useState(false)
  const [pinResetMsg, setPinResetMsg] = useState('')
  const [logoUrl, setLogoUrl] = useState(null)
  const [selectedNotebook, setSelectedNotebook] = useState(null)

  const [search, setSearch] = useState('')
  const [sort, setSort] = useState('due_desc')
  const [page, setPage] = useState(1)

  useEffect(() => {
    load()
    setLogoUrl(null)
    getBusinessLogoUrl(uid).then(setLogoUrl)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [uid])

  useEffect(() => {
    setPage(1)
  }, [search, sort])

  async function load() {
    setLoading(true)
    const [u, c] = await Promise.all([fetchUser(uid), fetchUserCustomers(uid)])
    setUser(u)
    setCustomers(c)
    setLoading(false)

    setStatsLoading(true)
    const [p, n] = await Promise.all([fetchAllPayments(c.map((x) => x.id)), fetchUserNotebooks(uid)])
    setPayments(p)
    setNotebooks(n)
    setStatsLoading(false)
  }

  const filteredSorted = useMemo(() => {
    let list = customers
    const term = search.trim().toLowerCase()
    if (term) {
      list = list.filter(
        (c) => (c.name || '').toLowerCase().includes(term) || (c.phone || '').toLowerCase().includes(term),
      )
    }
    const [key, dir] = sort.split('_')
    list = [...list].sort((a, b) => {
      let diff = 0
      if (key === 'name') diff = (a.name || '').localeCompare(b.name || '')
      else if (key === 'due') diff = (a.totalDue || 0) - (b.totalDue || 0)
      else if (key === 'created') diff = (a.createdAt?.toMillis?.() || 0) - (b.createdAt?.toMillis?.() || 0)
      return dir === 'asc' ? diff : -diff
    })
    return list
  }, [customers, search, sort])

  const totalPages = Math.max(1, Math.ceil(filteredSorted.length / PAGE_SIZE))
  const pageItems = filteredSorted.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)

  const totalDue = customers.reduce((sum, c) => sum + (c.totalDue || 0), 0)
  const totalCollected = payments.filter((p) => p.type === 'payment').reduce((sum, p) => sum + (p.amount || 0), 0)

  const handleExport = () => {
    const csv = toCsv(customers, [
      { label: 'Name', get: (c) => c.name || '' },
      { label: 'Phone', get: (c) => c.phone || '' },
      { label: 'Address', get: (c) => c.address || '' },
      { label: 'Total Due', get: (c) => c.totalDue || 0 },
      { label: 'Created', get: (c) => (c.createdAt?.toDate ? c.createdAt.toDate().toISOString() : '') },
    ])
    downloadCsv(`${(user?.name || uid).replace(/\s+/g, '_')}-customers.csv`, csv)
  }

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-7 w-7 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
      </div>
    )
  }
  if (!user) return <div className="p-6 text-sm text-ink-400">User not found.</div>

  const settings = user.settings || {}

  return (
    <div className="p-6 md:p-8">
      <Link to="/users" className="text-sm text-indigo-400 transition-colors hover:text-indigo-300">
        ← Back to users
      </Link>

      <div className="mt-3 flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-white">{user.name || '(no name)'}</h1>
          <p className="text-sm text-ink-400">{user.phone}</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <button
            onClick={async () => {
              setPinResetMsg('')
              setBusy(true)
              await resetUserPin(uid)
              setBusy(false)
              setPinResetMsg('PIN lock cleared for this user.')
            }}
            disabled={busy}
            className="rounded-lg border border-ink-700 bg-ink-850 px-3 py-1.5 text-sm font-medium text-ink-200 transition-colors hover:border-ink-600 hover:text-white disabled:opacity-60"
          >
            Reset PIN
          </button>
          <button
            onClick={() => setConfirmDisable(true)}
            className="rounded-lg border border-ink-700 bg-ink-850 px-3 py-1.5 text-sm font-medium text-ink-200 transition-colors hover:border-ink-600 hover:text-white"
          >
            {user.disabled ? 'Enable account' : 'Disable account'}
          </button>
          <button
            onClick={() => setConfirmDeleteAll(true)}
            className="rounded-lg bg-red-500/90 px-3 py-1.5 text-sm font-medium text-white shadow-[0_0_0_1px_rgba(248,113,113,0.4)] transition-colors hover:bg-red-500"
          >
            Delete all data
          </button>
        </div>
      </div>

      {pinResetMsg && <p className="mt-2 text-sm text-emerald-400">{pinResetMsg}</p>}

      {/* Mini stats */}
      <div className="mt-5 grid grid-cols-2 gap-3 md:grid-cols-4">
        <StatPill label="Customers" value={customers.length} />
        <StatPill label="Outstanding due" value={currency(totalDue)} accent="text-amber-400" />
        <StatPill
          label="Total collected"
          value={statsLoading ? '…' : currency(totalCollected)}
          accent="text-emerald-400"
        />
        <StatPill label="Notebooks" value={statsLoading ? '…' : notebooks.length} />
      </div>

      {/* Business profile + app settings */}
      <div className="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card">
          <div className="flex items-center gap-3">
            {logoUrl ? (
              <img src={logoUrl} alt="Business logo" className="h-10 w-10 rounded-lg object-cover" />
            ) : (
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-ink-800 text-xs text-ink-500">
                No logo
              </div>
            )}
            <p className="text-sm font-semibold text-white">Business profile</p>
          </div>
          <dl className="mt-3 space-y-2 text-sm">
            <div className="flex justify-between gap-4">
              <dt className="text-ink-400">Business name</dt>
              <dd className="text-right text-ink-200">{settings.businessName || '—'}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-ink-400">Owner name</dt>
              <dd className="text-right text-ink-200">{settings.ownerName || '—'}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-ink-400">Address</dt>
              <dd className="text-right text-ink-200">{settings.businessAddress || '—'}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-ink-400">Currency</dt>
              <dd className="text-right text-ink-200">{settings.currencySymbol || '৳'}</dd>
            </div>
          </dl>
        </div>

        <div className="rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card">
          <p className="text-sm font-semibold text-white">App settings</p>
          <dl className="mt-3 space-y-2 text-sm">
            <div className="flex justify-between gap-4">
              <dt className="text-ink-400">Theme</dt>
              <dd className="text-right text-ink-200">{settings.isDarkMode ? 'Dark' : 'Light'}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-ink-400">Language</dt>
              <dd className="text-right text-ink-200">{settings.languageCode === 'en' ? 'English' : 'বাংলা'}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-ink-400">Font scale</dt>
              <dd className="text-right text-ink-200">{settings.fontScale ?? 1}×</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-ink-400">App lock</dt>
              <dd className="text-right text-ink-200">{settings.appLockEnabled ? 'Enabled' : 'Disabled'}</dd>
            </div>
          </dl>
        </div>
      </div>

      {/* Notebooks */}
      {!statsLoading && notebooks.length > 0 && (
        <div className="mt-6 rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card">
          <p className="text-sm font-semibold text-white">Notebooks ({notebooks.length})</p>
          <div className="mt-3 flex flex-wrap gap-2">
            {notebooks.map((n) => (
              <button
                key={n.id}
                onClick={() => setSelectedNotebook(n)}
                className="rounded-full border border-ink-700 bg-ink-850 px-3 py-1 text-xs text-ink-200 transition-colors hover:border-indigo-500 hover:text-white"
              >
                {n.title || 'Untitled'}
              </button>
            ))}
          </div>
        </div>
      )}

      {selectedNotebook && (
        <NotebookDetailModal
          notebook={selectedNotebook}
          onClose={() => setSelectedNotebook(null)}
          onDeleted={async () => {
            setSelectedNotebook(null)
            const n = await fetchUserNotebooks(uid)
            setNotebooks(n)
          }}
        />
      )}

      {/* Customers table */}
      <div className="mt-6 flex flex-wrap items-center justify-between gap-3">
        <p className="text-sm font-semibold text-white">Customers</p>
        <div className="flex flex-wrap items-center gap-2">
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search customers…"
            className="w-56 rounded-lg border border-ink-700 bg-ink-850 px-3 py-1.5 text-sm text-white placeholder:text-ink-400 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
          />
          <select
            value={sort}
            onChange={(e) => setSort(e.target.value)}
            className="rounded-lg border border-ink-700 bg-ink-850 px-3 py-1.5 text-sm text-white outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
          >
            {SORT_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
          <button
            onClick={handleExport}
            className="rounded-lg border border-ink-700 bg-ink-850 px-3 py-1.5 text-sm font-medium text-ink-200 transition-colors hover:border-ink-600 hover:text-white"
          >
            Export CSV
          </button>
        </div>
      </div>

      <div className="mt-3 overflow-hidden rounded-2xl border border-ink-800 bg-ink-900/60 shadow-card">
        <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-ink-800 text-sm">
          <thead className="bg-ink-850/80">
            <tr>
              <th className="px-4 py-3 text-left font-medium text-ink-400">Customer</th>
              <th className="px-4 py-3 text-left font-medium text-ink-400">Phone</th>
              <th className="px-4 py-3 text-left font-medium text-ink-400">Due</th>
              <th className="px-4 py-3 text-left font-medium text-ink-400">Created</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-ink-800">
            {pageItems.map((c) => (
              <CustomerRow key={c.id} customer={c} onChanged={load} />
            ))}
            {filteredSorted.length === 0 && (
              <tr>
                <td colSpan={5} className="px-4 py-10 text-center text-ink-500">
                  No customers found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
        </div>
      </div>

      {totalPages > 1 && (
        <div className="mt-3 flex items-center justify-between text-sm text-ink-400">
          <p>
            {filteredSorted.length} customers · page {page} of {totalPages}
          </p>
          <div className="flex gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="rounded-lg border border-ink-700 bg-ink-850 px-3 py-1.5 font-medium text-ink-200 transition-colors hover:border-ink-600 hover:text-white disabled:opacity-40"
            >
              Prev
            </button>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="rounded-lg border border-ink-700 bg-ink-850 px-3 py-1.5 font-medium text-ink-200 transition-colors hover:border-ink-600 hover:text-white disabled:opacity-40"
            >
              Next
            </button>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={confirmDisable}
        title={user.disabled ? 'Enable this account?' : 'Disable this account?'}
        message={
          user.disabled
            ? 'This user will be able to log in again.'
            : 'This user will be signed out and blocked from using the app until re-enabled.'
        }
        confirmLabel={user.disabled ? 'Enable' : 'Disable'}
        onCancel={() => setConfirmDisable(false)}
        onConfirm={async () => {
          await toggleUserDisabled(uid, !user.disabled)
          setConfirmDisable(false)
          await load()
        }}
      />

      <ConfirmDialog
        open={confirmDeleteAll}
        title="Delete all data for this user?"
        message="This permanently deletes this user's profile, customers, payments, reminders, and notebooks. This cannot be undone. Their login account itself is not deleted."
        confirmLabel="Delete everything"
        onCancel={() => setConfirmDeleteAll(false)}
        onConfirm={async () => {
          setBusy(true)
          await deleteUserDataCascade(uid)
          setBusy(false)
          navigate('/users')
        }}
      />
    </div>
  )
}
