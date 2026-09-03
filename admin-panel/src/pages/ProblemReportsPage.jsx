import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  fetchProblemReports,
  updateProblemReportStatus,
  updateProblemReportPriority,
  updateProblemReportNotes,
  replyToProblemReport,
} from '../lib/adminApi'
import Modal from '../components/Modal'
import LoadError from '../components/LoadError'

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

const PRIORITY_OPTIONS = ['low', 'medium', 'high']

const PRIORITY_BADGE = {
  high: 'bg-red-500/15 text-red-400',
  medium: 'bg-amber-500/15 text-amber-400',
  low: 'bg-ink-700 text-ink-300',
}

function fmt(ts) {
  if (!ts?.toDate) return '—'
  return ts.toDate().toLocaleString()
}

function ageDays(ts) {
  if (!ts?.toDate) return null
  return Math.floor((Date.now() - ts.toDate().getTime()) / 86400000)
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

// Only meaningful while a report is still open — an old resolved report isn't "stale".
function AgeBadge({ item }) {
  if (item.status === 'resolved') return null
  const days = ageDays(item.createdAt)
  if (days === null) return null
  const tone = days >= 7 ? 'bg-red-500/15 text-red-400' : days >= 3 ? 'bg-amber-500/15 text-amber-400' : 'bg-ink-700 text-ink-300'
  return (
    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${tone}`}>
      {days === 0 ? 'today' : `${days}d open`}
    </span>
  )
}

function PriorityBadge({ priority }) {
  const p = priority || 'medium'
  return (
    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium capitalize ${PRIORITY_BADGE[p]}`}>
      {p}
    </span>
  )
}

export default function ProblemReportsPage() {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState('')
  const [tab, setTab] = useState('open')
  const [selected, setSelected] = useState(null)
  const [updating, setUpdating] = useState(false)
  const [notesDraft, setNotesDraft] = useState('')
  const [savingNotes, setSavingNotes] = useState(false)
  const [replyDraft, setReplyDraft] = useState('')
  const [sendingReply, setSendingReply] = useState(false)

  useEffect(() => {
    load()
  }, [])

  useEffect(() => {
    setNotesDraft(selected?.adminNotes || '')
    setReplyDraft('')
  }, [selected?.id])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      await refetchSilently()
    } catch (e) {
      setLoadError(e.message || 'Could not load problem reports.')
    } finally {
      setLoading(false)
    }
  }

  // Re-fetches without touching the full-page loading/error state — used after an edit
  // inside the already-open modal, so the table behind it doesn't flash back to a spinner.
  async function refetchSilently() {
    const data = await fetchProblemReports()
    setItems(data)
    return data
  }

  const filtered = useMemo(() => {
    if (tab === 'all') return items
    if (tab === 'open') return items.filter((i) => i.status !== 'resolved')
    return items.filter((i) => i.status === 'resolved')
  }, [items, tab])

  const openCount = useMemo(() => items.filter((i) => i.status !== 'resolved').length, [items])

  function patchLocal(id, patch) {
    setItems((prev) => prev.map((i) => (i.id === id ? { ...i, ...patch } : i)))
    setSelected((prev) => (prev && prev.id === id ? { ...prev, ...patch } : prev))
  }

  async function toggleStatus(item) {
    const nextStatus = item.status === 'resolved' ? 'open' : 'resolved'
    setUpdating(true)
    try {
      await updateProblemReportStatus(item.id, nextStatus)
      patchLocal(item.id, { status: nextStatus })
    } finally {
      setUpdating(false)
    }
  }

  async function changePriority(item, priority) {
    patchLocal(item.id, { priority })
    await updateProblemReportPriority(item.id, priority)
  }

  async function saveNotes(item) {
    setSavingNotes(true)
    try {
      await updateProblemReportNotes(item.id, notesDraft.trim())
      patchLocal(item.id, { adminNotes: notesDraft.trim() })
    } finally {
      setSavingNotes(false)
    }
  }

  async function sendReply(item) {
    if (!replyDraft.trim()) return
    setSendingReply(true)
    try {
      await replyToProblemReport(item.id, replyDraft.trim())
      const data = await refetchSilently()
      setSelected(data.find((i) => i.id === item.id) || null)
      setReplyDraft('')
    } finally {
      setSendingReply(false)
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
      ) : loadError ? (
        <LoadError message={loadError} onRetry={load} />
      ) : (
        <div className="mt-5 overflow-hidden rounded-2xl border border-ink-800 bg-ink-900/60 shadow-card">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-ink-800 text-sm">
              <thead className="bg-ink-850/80">
                <tr>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">Reporter</th>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">Category</th>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">Description</th>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">Priority</th>
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
                    <td className="px-4 py-3">
                      <PriorityBadge priority={item.priority} />
                    </td>
                    <td className="px-4 py-3 text-ink-500">
                      <div>{fmt(item.createdAt)}</div>
                      <AgeBadge item={item} />
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={item.status} />
                    </td>
                  </tr>
                ))}
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan={6} className="px-4 py-10 text-center text-ink-500">
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
              <div className="flex items-center gap-2">
                <AgeBadge item={selected} />
                <StatusBadge status={selected.status} />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs font-medium uppercase tracking-wide text-ink-500">Category</p>
                <p className="mt-1 text-sm text-white">{CATEGORY_LABELS[selected.category] || selected.category}</p>
              </div>
              <div>
                <p className="text-xs font-medium uppercase tracking-wide text-ink-500">Priority</p>
                <select
                  value={selected.priority || 'medium'}
                  onChange={(e) => changePriority(selected, e.target.value)}
                  className="mt-1 w-full rounded-lg border border-ink-700 bg-ink-850 px-2 py-1.5 text-sm capitalize text-white outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                >
                  {PRIORITY_OPTIONS.map((p) => (
                    <option key={p} value={p} className="capitalize">
                      {p}
                    </option>
                  ))}
                </select>
              </div>
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

            <div className="border-t border-ink-800 pt-4">
              <p className="text-xs font-medium uppercase tracking-wide text-ink-500">
                Internal notes <span className="normal-case text-ink-600">(never shown to the reporter)</span>
              </p>
              <textarea
                value={notesDraft}
                onChange={(e) => setNotesDraft(e.target.value)}
                rows={3}
                placeholder="e.g. reproduced on Android 13, waiting on customer for logs…"
                className="mt-2 w-full rounded-lg border border-ink-700 bg-ink-850 px-3 py-2 text-sm text-white placeholder:text-ink-500 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
              />
              <button
                onClick={() => saveNotes(selected)}
                disabled={savingNotes || notesDraft === (selected.adminNotes || '')}
                className="mt-2 rounded-lg border border-ink-700 bg-ink-850 px-3 py-1.5 text-sm font-medium text-ink-200 transition-colors hover:border-ink-600 hover:text-white disabled:opacity-40"
              >
                {savingNotes ? 'Saving…' : 'Save notes'}
              </button>
            </div>

            <div className="border-t border-ink-800 pt-4">
              <p className="text-xs font-medium uppercase tracking-wide text-ink-500">Reply to reporter</p>
              <p className="mt-1 text-xs text-ink-600">
                The app doesn't yet have a screen to show this back to the user — this saves your reply on the
                report as a record of what you told them (e.g. over phone/SMS), it isn't delivered automatically.
              </p>
              {selected.adminReply && (
                <div className="mt-2 rounded-lg border border-ink-700 bg-ink-850 p-3 text-sm text-ink-200">
                  <p className="whitespace-pre-wrap">{selected.adminReply}</p>
                  <p className="mt-1 text-xs text-ink-500">
                    {selected.adminReplyBy || 'admin'} · {fmt(selected.adminReplyAt)}
                  </p>
                </div>
              )}
              <textarea
                value={replyDraft}
                onChange={(e) => setReplyDraft(e.target.value)}
                rows={3}
                placeholder="Write a reply to record…"
                className="mt-2 w-full rounded-lg border border-ink-700 bg-ink-850 px-3 py-2 text-sm text-white placeholder:text-ink-500 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
              />
              <button
                onClick={() => sendReply(selected)}
                disabled={sendingReply || !replyDraft.trim()}
                className="mt-2 rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-3 py-1.5 text-sm font-medium text-white shadow-glow transition-transform hover:scale-[1.02] disabled:opacity-40 disabled:hover:scale-100"
              >
                {sendingReply ? 'Saving…' : 'Save reply'}
              </button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}
