import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { fetchProblemReports, updateProblemReportStatus } from '../lib/adminApi'
import Modal from '../components/Modal'

const CATEGORY_LABELS = {
  'Bug / App Crash': 'Bug / App Crash',
  'Payment Issue': 'Payment Issue',
  'Notification / Reminder Issue': 'Notification / Reminder Issue',
  'Feature Request': 'Feature Request',
  Other: 'Other',
}

const TABS = [
  { value: 'all', label: 'All' },
  { value: 'open', label: 'Open' },
  { value: 'resolved', label: 'Resolved' },
]

function fmt(ts) {
  if (!ts?.toDate) return '—'
  return ts.toDate().toLocaleString()
}

function StatusBadge({ status }) {
  const isOpen = status !== 'resolved'
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${
        isOpen ? 'bg-amber-500/15 text-amber-400' : 'bg-emerald-500/15 text-emerald-400'
      }`}
    >
      <span className={`h-1.5 w-1.5 rounded-full ${isOpen ? 'bg-amber-400' : 'bg-emerald-400'}`} />
      {isOpen ? 'Open' : 'Resolved'}
    </span>
  )
}

export default function ProblemReportsPage() {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState('open')
  const [selected, setSelected] = useState(null)
  const [updating, setUpdating] = useState(false)

  useEffect(() => {
    load()
  }, [])

  async function load() {
    setLoading(true)
    setItems(await fetchProblemReports())
    setLoading(false)
  }

  const filtered = useMemo(() => {
    if (tab === 'all') return items
    if (tab === 'open') return items.filter((i) => i.status !== 'resolved')
    return items.filter((i) => i.status === 'resolved')
  }, [items, tab])

  const openCount = useMemo(() => items.filter((i) => i.status !== 'resolved').length, [items])

  async function toggleStatus(item) {
    const nextStatus = item.status === 'resolved' ? 'open' : 'resolved'
    setUpdating(true)
    try {
      await updateProblemReportStatus(item.id, nextStatus)
      setItems((prev) => prev.map((i) => (i.id === item.id ? { ...i, status: nextStatus } : i)))
      setSelected((prev) => (prev && prev.id === item.id ? { ...prev, status: nextStatus } : prev))
    } finally {
      setUpdating(false)
    }
  }

  return (
    <div className="p-6 md:p-8">
      <h1 className="text-xl font-semibold text-white">Problem reports</h1>
      <p className="mt-1 text-sm text-ink-400">
        Submitted from Report a Problem in the app · {openCount} open, most recent first.
      </p>

      <div className="mt-4 flex gap-2">
        {TABS.map((t) => (
          <button
            key={t.value}
            onClick={() => setTab(t.value)}
            className={`rounded-lg border px-3 py-2 text-sm font-medium transition-colors ${
              tab === t.value
                ? 'border-indigo-500 bg-indigo-500/15 text-white'
                : 'border-ink-700 text-ink-300 hover:border-ink-600'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="mt-8 flex h-24 items-center justify-center">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
        </div>
      ) : (
        <div className="mt-5 overflow-hidden rounded-2xl border border-ink-800 bg-ink-900/60 shadow-card">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-ink-800 text-sm">
              <thead className="bg-ink-850/80">
                <tr>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">Reporter</th>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">Category</th>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">Description</th>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">Reported</th>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-ink-800">
                {filtered.map((item) => (
                  <tr
                    key={item.id}
                    onClick={() => setSelected(item)}
                    className="cursor-pointer transition-colors hover:bg-ink-800/60"
                  >
                    <td className="px-4 py-3">
                      <p className="font-medium text-white">{item.userName || '(no name)'}</p>
                      <p className="text-xs text-ink-400">{item.userPhone || '—'}</p>
                    </td>
                    <td className="px-4 py-3 text-ink-300">{CATEGORY_LABELS[item.category] || item.category}</td>
                    <td className="max-w-xs truncate px-4 py-3 text-ink-400">{item.description}</td>
                    <td className="px-4 py-3 text-ink-500">{fmt(item.createdAt)}</td>
                    <td className="px-4 py-3">
                      <StatusBadge status={item.status} />
                    </td>
                  </tr>
                ))}
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-4 py-10 text-center text-ink-500">
                      No problem reports here.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <Modal open={!!selected} title="Problem report" onClose={() => setSelected(null)}>
        {selected && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <Link
                  to={`/users/${selected.userId}`}
                  className="font-medium text-indigo-400 transition-colors hover:text-indigo-300"
                >
                  {selected.userName || '(no name)'}
                </Link>
                <p className="text-xs text-ink-400">{selected.userPhone || '—'}</p>
              </div>
              <StatusBadge status={selected.status} />
            </div>

            <div>
              <p className="text-xs font-medium uppercase tracking-wide text-ink-500">Category</p>
              <p className="mt-1 text-sm text-white">{CATEGORY_LABELS[selected.category] || selected.category}</p>
            </div>

            <div>
              <p className="text-xs font-medium uppercase tracking-wide text-ink-500">Description</p>
              <p className="mt-1 whitespace-pre-wrap text-sm text-ink-200">{selected.description}</p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs font-medium uppercase tracking-wide text-ink-500">App version</p>
                <p className="mt-1 text-sm text-ink-300">{selected.appVersion || '—'}</p>
              </div>
              <div>
                <p className="text-xs font-medium uppercase tracking-wide text-ink-500">Platform</p>
                <p className="mt-1 text-sm text-ink-300">{selected.platform || '—'}</p>
              </div>
            </div>

            <p className="text-xs text-ink-500">Reported {fmt(selected.createdAt)}</p>

            <button
              onClick={() => toggleStatus(selected)}
              disabled={updating}
              className="w-full rounded-lg bg-indigo-500 px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-indigo-400 disabled:opacity-60"
            >
              {selected.status === 'resolved' ? 'Reopen report' : 'Mark as resolved'}
            </button>
          </div>
        )}
      </Modal>
    </div>
  )
}
