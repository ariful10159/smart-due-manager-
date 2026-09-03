import { useEffect, useState } from 'react'
import { sendPushNotification, fetchPushNotifications } from '../lib/adminApi'
import { useAuth } from '../context/AuthContext'
import ConfirmDialog from '../components/ConfirmDialog'
import LoadError from '../components/LoadError'

const inputClass =
  'w-full rounded-lg border border-ink-700 bg-ink-850 px-3 py-2.5 text-sm text-white placeholder:text-ink-400 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500'

const TARGET_GROUPS = [
  { value: 'all', label: 'All users' },
  { value: 'active', label: 'Active users' },
  { value: 'newSignups', label: 'New signups' },
]

const TARGET_GROUP_LABELS = Object.fromEntries(TARGET_GROUPS.map((g) => [g.value, g.label]))

function fmt(ts) {
  if (!ts?.toDate) return '—'
  return ts.toDate().toLocaleString()
}

export default function PushNotificationPage() {
  const { isSuperAdmin } = useAuth()

  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [targetGroup, setTargetGroup] = useState('all')
  const [newSignupDays, setNewSignupDays] = useState(7)
  const [confirmSend, setConfirmSend] = useState(false)
  const [sending, setSending] = useState(false)
  const [sendError, setSendError] = useState('')
  const [lastResult, setLastResult] = useState(null)

  const [history, setHistory] = useState([])
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState('')

  useEffect(() => {
    load()
  }, [])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      setHistory(await fetchPushNotifications())
    } catch (e) {
      setLoadError(e.message || 'Could not load push notification history.')
    } finally {
      setLoading(false)
    }
  }

  if (!isSuperAdmin) {
    return (
      <div className="flex h-64 flex-col items-center justify-center gap-2 p-6 text-center">
        <p className="text-lg font-semibold text-white">Not authorized</p>
        <p className="text-sm text-ink-300">Only super admins can send push notifications.</p>
      </div>
    )
  }

  const canSend =
    title.trim().length > 0 &&
    body.trim().length > 0 &&
    (targetGroup !== 'newSignups' || (Number.isInteger(Number(newSignupDays)) && Number(newSignupDays) > 0))

  async function handleSend() {
    setSending(true)
    setSendError('')
    try {
      const result = await sendPushNotification({
        title: title.trim(),
        body: body.trim(),
        targetGroup,
        newSignupDays: targetGroup === 'newSignups' ? Number(newSignupDays) : null,
      })
      setLastResult(result)
      setTitle('')
      setBody('')
      setConfirmSend(false)
      await load()
    } catch (e) {
      setSendError(e.message || 'Could not send this push notification.')
      setConfirmSend(false)
    } finally {
      setSending(false)
    }
  }

  return (
    <div className="max-w-2xl p-6 md:p-8">
      <h1 className="text-xl font-semibold text-white">Push Notification</h1>
      <p className="mt-1 text-sm text-ink-400">
        Sends a real phone notification (system tray) to the chosen group of users, even if the app is closed. Only
        users whose device has registered a notification token will actually receive it — see the coverage numbers
        after sending.
      </p>

      <div className="mt-5 rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card">
        <div className="mb-3 flex gap-2">
          {TARGET_GROUPS.map((g) => (
            <button
              key={g.value}
              onClick={() => setTargetGroup(g.value)}
              className={`flex-1 rounded-lg border px-3 py-2 text-sm font-medium transition-colors ${
                targetGroup === g.value
                  ? 'border-indigo-500 bg-indigo-500/15 text-white'
                  : 'border-ink-700 text-ink-300 hover:border-ink-600'
              }`}
            >
              {g.label}
            </button>
          ))}
        </div>

        <div className="space-y-3">
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Title"
            className={inputClass}
          />
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder="Message"
            rows={3}
            className={inputClass}
          />

          {targetGroup === 'newSignups' && (
            <label className="block text-xs text-ink-400">
              Signed up within the last (days)
              <input
                type="number"
                min={1}
                max={365}
                value={newSignupDays}
                onChange={(e) => setNewSignupDays(e.target.value)}
                className={`${inputClass} mt-1`}
              />
            </label>
          )}
        </div>

        {sendError && <p className="mt-3 text-sm text-red-400">{sendError}</p>}

        <div className="mt-4 flex justify-end">
          <button
            onClick={() => setConfirmSend(true)}
            disabled={!canSend || sending}
            className="rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-4 py-1.5 text-sm font-medium text-white shadow-glow transition-transform hover:scale-[1.02] disabled:opacity-60 disabled:hover:scale-100"
          >
            {sending ? 'Sending…' : 'Send'}
          </button>
        </div>
      </div>

      {lastResult && (
        <div className="mt-4 rounded-2xl border border-emerald-500/30 bg-emerald-500/10 p-4 text-sm text-emerald-200">
          <p className="font-semibold">Sent.</p>
          <p className="mt-1 text-emerald-300/90">
            {lastResult.targetCount} in target group · {lastResult.sentCount} delivered ·{' '}
            {lastResult.skippedNoTokenCount} had no token · {lastResult.failedCount} failed ·{' '}
            {lastResult.invalidTokenCount} stale tokens cleaned up
          </p>
        </div>
      )}

      <h2 className="mt-8 text-sm font-semibold text-ink-300">History</h2>

      {loading ? (
        <div className="mt-4 flex h-24 items-center justify-center">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
        </div>
      ) : loadError ? (
        <LoadError message={loadError} onRetry={load} />
      ) : (
        <div className="mt-3 space-y-3">
          {history.map((item) => (
            <div key={item.id} className="rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card">
              <div className="flex flex-wrap items-center gap-2">
                <p className="font-semibold text-white">{item.title}</p>
                <span className="shrink-0 rounded-full bg-ink-700 px-2 py-0.5 text-xs font-medium text-ink-300">
                  {TARGET_GROUP_LABELS[item.targetGroup] || item.targetGroup}
                  {item.targetGroup === 'newSignups' && item.newSignupDays ? ` (${item.newSignupDays}d)` : ''}
                </span>
              </div>
              <p className="mt-1 text-sm text-ink-300">{item.body}</p>
              <p className="mt-2 text-xs text-ink-500">
                {fmt(item.sentAt)} · {item.sentByEmail || item.sentBy} · {item.targetCount} target ·{' '}
                {item.sentCount} delivered · {item.skippedNoTokenCount} no token · {item.failedCount} failed
              </p>
            </div>
          ))}
          {history.length === 0 && (
            <p className="rounded-2xl border border-ink-800 bg-ink-900/60 p-8 text-center text-sm text-ink-500">
              No push notifications sent yet.
            </p>
          )}
        </div>
      )}

      <ConfirmDialog
        open={confirmSend}
        title="Send push notification?"
        message={`This will send "${title}" to ${TARGET_GROUP_LABELS[targetGroup].toLowerCase()}. This can't be undone.`}
        confirmLabel="Send"
        onCancel={() => setConfirmSend(false)}
        onConfirm={handleSend}
      />
    </div>
  )
}
