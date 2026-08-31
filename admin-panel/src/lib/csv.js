function escapeCsvValue(value) {
  const s = String(value ?? '')
  if (/[",\n]/.test(s)) return '"' + s.replace(/"/g, '""') + '"'
  return s
}

// columns: [{ label, get: (row) => value }]
export function toCsv(rows, columns) {
  const headerLine = columns.map((c) => escapeCsvValue(c.label)).join(',')
  const lines = rows.map((row) => columns.map((c) => escapeCsvValue(c.get(row))).join(','))
  return [headerLine, ...lines].join('\n')
}

export function downloadCsv(filename, csvContent) {
  // Leading BOM so Bengali text opens correctly in Excel.
  const blob = new Blob(['﻿' + csvContent], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}
