import { useRef, useState } from 'react'
import * as XLSX from 'xlsx'
import { addFaq } from '../lib/adminApi'

const COLUMNS = ['order', 'questionEn', 'answerEn', 'questionBn', 'answerBn']

const SAMPLE_ROW = {
  order: 1,
  questionEn: 'How do SMS reminders work?',
  answerEn:
    "Reminder SMS are sent from your phone's own SIM. The app opens the SMS app separately for each customer with the message prefilled — you have to press Send yourself.",
  questionBn: 'SMS রিমাইন্ডার কীভাবে কাজ করে?',
  answerBn:
    'রিমাইন্ডার SMS আপনার ফোনের নিজস্ব SIM থেকে পাঠানো হয়। অ্যাপ প্রতিটা কাস্টমারের জন্য আলাদাভাবে SMS app খুলে মেসেজ prefilled অবস্থায় দেখায়, আপনাকে নিজে Send বাটনে চাপতে হয়।',
}

function downloadTemplate() {
  const ws = XLSX.utils.json_to_sheet([SAMPLE_ROW], { header: COLUMNS })
  ws['!cols'] = [{ wch: 8 }, { wch: 40 }, { wch: 60 }, { wch: 40 }, { wch: 60 }]
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, 'FAQ')
  XLSX.writeFile(wb, 'faq-template.xlsx')
}

// Case-insensitive lookup so re-typed/reordered headers (Order vs order) still work.
function normalizeRow(raw, fallbackOrder) {
  const lower = {}
  for (const [k, v] of Object.entries(raw)) {
    lower[String(k).trim().toLowerCase()] = v
  }
  const orderValue = Number(lower['order'])
  return {
    order: Number.isFinite(orderValue) && lower['order'] !== '' ? orderValue : fallbackOrder,
    questionEn: String(lower['questionen'] ?? '').trim(),
    answerEn: String(lower['answeren'] ?? '').trim(),
    questionBn: String(lower['questionbn'] ?? '').trim(),
    answerBn: String(lower['answerbn'] ?? '').trim(),
  }
}

export default function FaqExcelImport({ nextOrder, onImported }) {
  const fileInputRef = useRef(null)
  const [rows, setRows] = useState(null)
  const [fileName, setFileName] = useState('')
  const [parseError, setParseError] = useState('')
  const [importing, setImporting] = useState(false)
  const [importResult, setImportResult] = useState('')

  const handleFile = async (file) => {
    setParseError('')
    setImportResult('')
    setFileName(file.name)
    try {
      const buffer = await file.arrayBuffer()
      const workbook = XLSX.read(buffer, { type: 'array' })
      const sheet = workbook.Sheets[workbook.SheetNames[0]]
      const raw = XLSX.utils.sheet_to_json(sheet, { defval: '' })

      const normalized = raw
        .map((r, i) => normalizeRow(r, nextOrder + i))
        .filter((r) => (r.questionEn && r.answerEn) || (r.questionBn && r.answerBn))

      if (normalized.length === 0) {
        setParseError('No valid rows found — each row needs at least an English or Bengali question + answer.')
        setRows(null)
        return
      }
      setRows(normalized)
    } catch (e) {
      setParseError(e.message || 'Could not read this file.')
      setRows(null)
    }
  }

  const handleImport = async () => {
    if (!rows) return
    setImporting(true)
    try {
      for (const row of rows) {
        await addFaq(row)
      }
      setImportResult(`Imported ${rows.length} FAQ item${rows.length === 1 ? '' : 's'}.`)
      setRows(null)
      setFileName('')
      if (fileInputRef.current) fileInputRef.current.value = ''
      await onImported()
    } catch (e) {
      setParseError(e.message || 'Import failed partway through — check what got added below.')
    } finally {
      setImporting(false)
    }
  }

  return (
    <div className="rounded-2xl border border-dashed border-ink-700 bg-ink-900/40 p-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="font-semibold text-white">Bulk import from Excel</p>
          <p className="mt-1 text-sm text-ink-400">
            Columns: order, questionEn, answerEn, questionBn, answerBn. Each row needs at least one language filled
            in.
          </p>
        </div>
        <div className="flex shrink-0 gap-2">
          <button
            onClick={downloadTemplate}
            className="rounded-lg border border-ink-700 px-3 py-1.5 text-sm font-medium text-ink-300 transition-colors hover:border-indigo-500 hover:text-white"
          >
            ⬇ Download template
          </button>
          <button
            onClick={() => fileInputRef.current?.click()}
            className="rounded-lg border border-ink-700 px-3 py-1.5 text-sm font-medium text-ink-300 transition-colors hover:border-indigo-500 hover:text-white"
          >
            ⬆ Upload .xlsx
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept=".xlsx,.xls"
            className="hidden"
            onChange={(e) => e.target.files?.[0] && handleFile(e.target.files[0])}
          />
        </div>
      </div>

      {parseError && <p className="mt-3 text-sm text-red-400">{parseError}</p>}
      {importResult && <p className="mt-3 text-sm text-emerald-400">{importResult}</p>}

      {rows && (
        <div className="mt-4">
          <p className="mb-2 text-xs font-medium text-ink-400">
            {fileName} — {rows.length} row{rows.length === 1 ? '' : 's'} ready to import
          </p>
          <div className="max-h-56 overflow-y-auto rounded-lg border border-ink-700">
            {rows.map((r, i) => (
              <div key={i} className={`p-3 text-xs ${i !== 0 ? 'border-t border-ink-700' : ''}`}>
                <p className="font-medium text-ink-200">
                  #{r.order} — {r.questionEn || r.questionBn}
                </p>
                <p className="mt-0.5 text-ink-500">{r.answerEn || r.answerBn}</p>
              </div>
            ))}
          </div>
          <div className="mt-3 flex justify-end gap-2">
            <button
              onClick={() => {
                setRows(null)
                setFileName('')
                if (fileInputRef.current) fileInputRef.current.value = ''
              }}
              className="rounded-lg px-3 py-1.5 text-sm font-medium text-ink-300 transition-colors hover:bg-ink-700 hover:text-white"
            >
              Cancel
            </button>
            <button
              onClick={handleImport}
              disabled={importing}
              className="rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-4 py-1.5 text-sm font-medium text-white shadow-glow transition-transform hover:scale-[1.02] disabled:opacity-60 disabled:hover:scale-100"
            >
              {importing ? 'Importing…' : `Import ${rows.length} item${rows.length === 1 ? '' : 's'}`}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
