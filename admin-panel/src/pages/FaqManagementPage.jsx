import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { fetchFaqs, addFaq, updateFaq, deleteFaq } from '../lib/adminApi'
import ConfirmDialog from '../components/ConfirmDialog'
import FaqExcelImport from '../components/FaqExcelImport'

const inputClass =
  'w-full rounded-lg border border-ink-700 bg-ink-850 px-3 py-2.5 text-sm text-white placeholder:text-ink-400 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500'

const labelClass = 'mb-1 block text-xs text-ink-400'

function FaqForm({ initial, nextOrder, onCancel, onSave }) {
  const [questionEn, setQuestionEn] = useState(initial?.questionEn || '')
  const [answerEn, setAnswerEn] = useState(initial?.answerEn || '')
  const [questionBn, setQuestionBn] = useState(initial?.questionBn || '')
  const [answerBn, setAnswerBn] = useState(initial?.answerBn || '')
  const [order, setOrder] = useState(initial?.order ?? nextOrder)
  const [saving, setSaving] = useState(false)

  // At least one language needs both a question and an answer.
  const canSave = (questionEn.trim() && answerEn.trim()) || (questionBn.trim() && answerBn.trim())

  const handleSave = async () => {
    setSaving(true)
    await onSave({
      questionEn: questionEn.trim(),
      answerEn: answerEn.trim(),
      questionBn: questionBn.trim(),
      answerBn: answerBn.trim(),
      order: Number(order) || 0,
    })
    setSaving(false)
  }

  return (
    <div className="rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="space-y-2">
          <p className="text-xs font-semibold text-ink-300">English</p>
          <div>
            <label className={labelClass}>Question</label>
            <input value={questionEn} onChange={(e) => setQuestionEn(e.target.value)} className={inputClass} />
          </div>
          <div>
            <label className={labelClass}>Answer</label>
            <textarea value={answerEn} onChange={(e) => setAnswerEn(e.target.value)} rows={4} className={inputClass} />
          </div>
        </div>
        <div className="space-y-2">
          <p className="text-xs font-semibold text-ink-300">বাংলা</p>
          <div>
            <label className={labelClass}>প্রশ্ন</label>
            <input value={questionBn} onChange={(e) => setQuestionBn(e.target.value)} className={inputClass} />
          </div>
          <div>
            <label className={labelClass}>উত্তর</label>
            <textarea value={answerBn} onChange={(e) => setAnswerBn(e.target.value)} rows={4} className={inputClass} />
          </div>
        </div>
      </div>

      <div className="mt-3">
        <label className={labelClass}>Order (lower shows first)</label>
        <input
          type="number"
          value={order}
          onChange={(e) => setOrder(e.target.value)}
          className={`${inputClass} w-32`}
        />
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

export default function FaqManagementPage() {
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
    setItems(await fetchFaqs())
    setLoading(false)
  }

  async function handleCreate(data) {
    await addFaq(data)
    setCreating(false)
    await load()
  }

  async function handleUpdate(id, data) {
    await updateFaq(id, data)
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

  const nextOrder = items.length > 0 ? Math.max(...items.map((i) => i.order || 0)) + 1 : 0

  return (
    <div className="max-w-3xl p-6 md:p-8">
      <Link to="/app-config" className="text-sm font-medium text-indigo-400 transition-colors hover:text-indigo-300">
        ← App Config
      </Link>
      <div className="mt-2 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-white">FAQ Management</h1>
          <p className="mt-1 text-sm text-ink-400">
            Shown on the app's Help &amp; Support screen, sorted by order. If this list is empty, the app falls back
            to its built-in FAQ.
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

      <div className="mt-5">
        <FaqExcelImport nextOrder={nextOrder} onImported={load} />
      </div>

      {creating && (
        <div className="mt-5">
          <FaqForm nextOrder={nextOrder} onCancel={() => setCreating(false)} onSave={handleCreate} />
        </div>
      )}

      <div className="mt-5 space-y-3">
        {items.map((item) =>
          editingId === item.id ? (
            <FaqForm
              key={item.id}
              initial={item}
              nextOrder={nextOrder}
              onCancel={() => setEditingId(null)}
              onSave={(data) => handleUpdate(item.id, data)}
            />
          ) : (
            <div key={item.id} className="rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="font-semibold text-white">{item.questionEn || item.questionBn}</p>
                  <p className="mt-1 text-sm text-ink-300">{item.answerEn || item.answerBn}</p>
                  {item.questionBn && (
                    <p className="mt-2 text-sm text-ink-400">
                      <span className="font-semibold">{item.questionBn}</span> — {item.answerBn}
                    </p>
                  )}
                  <p className="mt-2 text-xs text-ink-500">order {item.order ?? 0}</p>
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
            No FAQ items yet — the app is showing its built-in default FAQ.
          </p>
        )}
      </div>

      <ConfirmDialog
        open={!!confirmDelete}
        title="Delete FAQ item?"
        message={`"${confirmDelete?.questionEn || confirmDelete?.questionBn || ''}" will be permanently removed.`}
        confirmLabel="Delete"
        onCancel={() => setConfirmDelete(null)}
        onConfirm={async () => {
          await deleteFaq(confirmDelete.id)
          setConfirmDelete(null)
          await load()
        }}
      />
    </div>
  )
}
