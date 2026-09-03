import { useState } from 'react'

export default function ConfirmDialog({ open, title, message, confirmLabel = 'Confirm', onConfirm, onCancel }) {
  const [busy, setBusy] = useState(false)

  if (!open) return null

  // Guards against a fast double-click firing onConfirm twice before the dialog closes.
  const handleConfirm = async () => {
    if (busy) return
    setBusy(true)
    try {
      await onConfirm()
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm animate-fadeIn">
      <div className="w-full max-w-sm rounded-2xl border border-ink-700 bg-ink-850 p-5 shadow-card">
        <h3 className="text-base font-semibold text-white">{title}</h3>
        <p className="mt-2 text-sm text-ink-300">{message}</p>
        <div className="mt-5 flex justify-end gap-2">
          <button
            onClick={onCancel}
            disabled={busy}
            className="rounded-lg px-3 py-1.5 text-sm font-medium text-ink-300 transition-colors hover:bg-ink-700 hover:text-white disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            onClick={handleConfirm}
            disabled={busy}
            className="rounded-lg bg-red-500/90 px-3 py-1.5 text-sm font-medium text-white shadow-[0_0_0_1px_rgba(248,113,113,0.4)] transition-colors hover:bg-red-500 disabled:opacity-60"
          >
            {busy ? 'Working…' : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  )
}
