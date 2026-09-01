import { useEffect, useState } from 'react'
import {
  fetchAnnouncements,
  createAnnouncement,
  updateAnnouncement,
  deleteAnnouncement,
  compressImageToDataUrl,
  dataUrlByteSize,
} from '../lib/adminApi'
import ConfirmDialog from '../components/ConfirmDialog'

const inputClass =
  'w-full rounded-lg border border-ink-700 bg-ink-850 px-3 py-2.5 text-sm text-white placeholder:text-ink-400 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500'

const FREQUENCY_OPTIONS = [
  { value: 'always', label: 'Every time the app opens' },
  { value: 'daily', label: 'Once per day' },
  { value: 'weekly', label: 'Once per week' },
  { value: 'once', label: 'Only once (ever)' },
]

const FREQUENCY_LABELS = Object.fromEntries(FREQUENCY_OPTIONS.map((o) => [o.value, o.label]))

function toDatetimeLocal(ts) {
  if (!ts?.toDate) return ''
  const d = ts.toDate()
  const pad = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function fromDatetimeLocal(value) {
  return value ? new Date(value) : null
}

function fmt(ts) {
  if (!ts?.toDate) return '—'
  return ts.toDate().toLocaleString()
}

function AnnouncementForm({ initial, onCancel, onSave }) {
  const [type, setType] = useState(initial?.type || 'message')
  const [title, setTitle] = useState(initial?.title || '')
  const [message, setMessage] = useState(initial?.message || '')
  const [active, setActive] = useState(initial?.active ?? true)
  const [startAt, setStartAt] = useState(toDatetimeLocal(initial?.startAt))
  const [endAt, setEndAt] = useState(toDatetimeLocal(initial?.endAt))
  const [frequency, setFrequency] = useState(initial?.frequency || 'always')
  const [imageDataUrl, setImageDataUrl] = useState(initial?.imageUrl || null)
  const [imageError, setImageError] = useState('')
  const [compressing, setCompressing] = useState(false)
  const [saving, setSaving] = useState(false)

  const handleImagePick = async (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    setImageError('')
    setCompressing(true)
    try {
      setImageDataUrl(await compressImageToDataUrl(file))
    } catch {
      setImageError('Could not process this image. Try a different file.')
    } finally {
      setCompressing(false)
    }
  }

  const canSave = (type === 'popup' ? !!imageDataUrl : message.trim().length > 0) && !compressing

  const handleSave = async () => {
    setSaving(true)
    await onSave({
      type,
      title,
      message,
      active,
      startAt: fromDatetimeLocal(startAt),
      endAt: fromDatetimeLocal(endAt),
      ...(type === 'popup' ? { imageUrl: imageDataUrl, frequency } : {}),
    })
    setSaving(false)
  }

  return (
    <div className="rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card">
      <div className="mb-3 flex gap-2">
        {[
          { value: 'message', label: '📣 Message (ticker banner)' },
          { value: 'popup', label: '🖼️ Image popup (shown on app open)' },
        ].map((t) => (
          <button
            key={t.value}
            onClick={() => setType(t.value)}
            className={`flex-1 rounded-lg border px-3 py-2 text-sm font-medium transition-colors ${
              type === t.value
                ? 'border-indigo-500 bg-indigo-500/15 text-white'
                : 'border-ink-700 text-ink-300 hover:border-ink-600'
            }`}
          >
            {t.label}
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

        {type === 'popup' ? (
          <div>
            <label className="block text-xs text-ink-400">
              Popup image — any size, auto-compressed to fit
            </label>
            <input
              type="file"
              accept="image/*"
              onChange={handleImagePick}
              disabled={compressing}
              className="mt-1 w-full text-sm text-ink-300 file:mr-3 file:rounded-lg file:border-0 file:bg-indigo-600 file:px-3 file:py-2 file:text-sm file:font-medium file:text-white hover:file:bg-indigo-500 disabled:opacity-60"
            />
            {compressing && <p className="mt-2 text-sm text-ink-400">Compressing…</p>}
            {imageError && <p className="mt-2 text-sm text-red-400">{imageError}</p>}
            {imageDataUrl && !compressing && (
              <>
                <img
                  src={imageDataUrl}
                  alt="Popup preview"
                  className="mt-3 max-h-56 w-full rounded-lg border border-ink-700 object-contain"
                />
                <p className="mt-1 text-xs text-ink-500">{Math.round(dataUrlByteSize(imageDataUrl) / 1024)}KB</p>
              </>
            )}
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Caption (optional)"
              rows={2}
              className={`${inputClass} mt-3`}
            />
            <label className="mt-3 block text-xs text-ink-400">
              How often should it show?
              <select
                value={frequency}
                onChange={(e) => setFrequency(e.target.value)}
                className={`${inputClass} mt-1`}
              >
                {FREQUENCY_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </select>
            </label>
          </div>
        ) : (
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Message"
            rows={3}
            className={inputClass}
          />
        )}

        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <label className="block text-xs text-ink-400">
            Starts (optional)
            <input
              type="datetime-local"
              value={startAt}
              onChange={(e) => setStartAt(e.target.value)}
              className={`${inputClass} mt-1`}
            />
          </label>
          <label className="block text-xs text-ink-400">
            Ends (optional)
            <input
              type="datetime-local"
              value={endAt}
              onChange={(e) => setEndAt(e.target.value)}
              className={`${inputClass} mt-1`}
            />
          </label>
        </div>
        <label className="flex items-center gap-2 text-sm text-ink-200">
          <input
            type="checkbox"
            checked={active}
            onChange={(e) => setActive(e.target.checked)}
            className="h-4 w-4 rounded border-ink-600 bg-ink-850 text-indigo-500 focus:ring-indigo-500 focus:ring-offset-0"
          />
          Active
        </label>
      </div>
      <div className="mt-4 flex justify-end gap-2">
        <button
          onClick={onCancel}
          className="rounded-lg px-3 py-1.5 text-sm font-medium text-ink-300 transition-colors hover:bg-ink-700 hover:text-white"
        >
          Cancel
        </button>
        <button
          onClick={handleSave}
          disabled={saving || !canSave}
          className="rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-4 py-1.5 text-sm font-medium text-white shadow-glow transition-transform hover:scale-[1.02] disabled:opacity-60 disabled:hover:scale-100"
        >
          {saving ? 'Saving…' : 'Save'}
        </button>
      </div>
    </div>
  )
}

export default function AnnouncementPage() {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [creating, setCreating] = useState(false)
  const [editingId, setEditingId] = useState(null)
  const [confirmDelete, setConfirmDelete] = useState(null)

  useEffect(() => {
    load()
  }, [])

  async function load() {
    setLoading(true)
    setItems(await fetchAnnouncements())
    setLoading(false)
  }

  async function handleCreate(data) {
    await createAnnouncement(data)
    setCreating(false)
    await load()
  }

  async function handleUpdate(id, data) {
    await updateAnnouncement(id, data)
    setEditingId(null)
    await load()
  }

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-7 w-7 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
      </div>
    )
  }

  return (
    <div className="max-w-2xl p-6 md:p-8">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-white">Announcements</h1>
          <p className="mt-1 text-sm text-ink-400">
            <strong>Message</strong> shows as a scrolling banner on the home screen. <strong>Image popup</strong>{' '}
            shows as a full-image dialog, at the frequency you set. Multiple can be scheduled; the most recently
            updated active one per type (within its start/end window, if set) is shown.
          </p>
        </div>
        {!creating && (
          <button
            onClick={() => setCreating(true)}
            className="rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-4 py-2 text-sm font-medium text-white shadow-glow transition-transform hover:scale-[1.02]"
          >
            + New
          </button>
        )}
      </div>

      {creating && (
        <div className="mt-5">
          <AnnouncementForm onCancel={() => setCreating(false)} onSave={handleCreate} />
        </div>
      )}

      <div className="mt-5 space-y-3">
        {items.map((item) =>
          editingId === item.id ? (
            <AnnouncementForm
              key={item.id}
              initial={item}
              onCancel={() => setEditingId(null)}
              onSave={(data) => handleUpdate(item.id, data)}
            />
          ) : (
            <div key={item.id} className="rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card">
              <div className="flex items-start justify-between gap-3">
                <div className="flex min-w-0 gap-3">
                  {item.type === 'popup' && item.imageUrl && (
                    <img
                      src={item.imageUrl}
                      alt=""
                      className="h-14 w-14 shrink-0 rounded-lg border border-ink-700 object-cover"
                    />
                  )}
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="truncate font-semibold text-white">{item.title || '(no title)'}</p>
                      <span className="shrink-0 rounded-full bg-ink-700 px-2 py-0.5 text-xs font-medium text-ink-300">
                        {item.type === 'popup' ? '🖼️ Popup' : '📣 Message'}
                      </span>
                      {item.type === 'popup' && (
                        <span className="shrink-0 rounded-full bg-indigo-500/10 px-2 py-0.5 text-xs font-medium text-indigo-300">
                          {FREQUENCY_LABELS[item.frequency] || FREQUENCY_LABELS.always}
                        </span>
                      )}
                      {item.active ? (
                        <span className="shrink-0 rounded-full bg-emerald-500/10 px-2 py-0.5 text-xs font-medium text-emerald-400 ring-1 ring-inset ring-emerald-500/30">
                          Active
                        </span>
                      ) : (
                        <span className="shrink-0 rounded-full bg-ink-700 px-2 py-0.5 text-xs font-medium text-ink-300">
                          Inactive
                        </span>
                      )}
                    </div>
                    {item.message && <p className="mt-1 text-sm text-ink-300">{item.message}</p>}
                    <p className="mt-2 text-xs text-ink-500">
                      {item.startAt || item.endAt
                        ? `${item.startAt ? fmt(item.startAt) : 'always'} → ${item.endAt ? fmt(item.endAt) : 'no end'}`
                        : 'No schedule window'}
                    </p>
                  </div>
                </div>
                <div className="flex shrink-0 gap-3">
                  <button
                    onClick={() => setEditingId(item.id)}
                    className="text-sm font-medium text-indigo-400 transition-colors hover:text-indigo-300"
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => setConfirmDelete(item)}
                    className="text-sm font-medium text-red-400 transition-colors hover:text-red-300"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          ),
        )}
        {items.length === 0 && !creating && (
          <p className="rounded-2xl border border-ink-800 bg-ink-900/60 p-8 text-center text-sm text-ink-500">
            No announcements yet.
          </p>
        )}
      </div>

      <ConfirmDialog
        open={!!confirmDelete}
        title="Delete announcement?"
        message={`"${confirmDelete?.title || confirmDelete?.message || ''}" will be permanently removed.`}
        confirmLabel="Delete"
        onCancel={() => setConfirmDelete(null)}
        onConfirm={async () => {
          await deleteAnnouncement(confirmDelete.id)
          setConfirmDelete(null)
          await load()
        }}
      />
    </div>
  )
}
