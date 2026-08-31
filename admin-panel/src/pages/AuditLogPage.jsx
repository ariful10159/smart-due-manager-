import { useEffect, useState } from 'react'
import { fetchAuditLog } from '../lib/adminApi'

const ACTION_LABELS = {
  disable_user: 'Disabled account',
  enable_user: 'Enabled account',
  reset_pin: 'Reset PIN',
  delete_user_data: 'Deleted all user data',
  update_customer: 'Edited customer',
  delete_customer: 'Deleted customer',
  update_payment: 'Edited payment',
  delete_payment: 'Deleted payment',
  delete_notebook: 'Deleted notebook',
  create_announcement: 'Created announcement',
  update_announcement: 'Updated announcement',
  delete_announcement: 'Deleted announcement',
  add_admin: 'Granted admin access',
  remove_admin: 'Removed admin access',
}

function fmt(ts) {
  if (!ts?.toDate) return '—'
  return ts.toDate().toLocaleString()
}

export default function AuditLogPage() {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    load()
  }, [])

  async function load() {
    setLoading(true)
    setItems(await fetchAuditLog())
    setLoading(false)
  }

  return (
    <div className="p-6 md:p-8">
      <h1 className="text-xl font-semibold text-white">Audit log</h1>
      <p className="mt-1 text-sm text-ink-400">Every action taken from this admin panel, most recent first.</p>

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
                <th className="px-4 py-3 text-left font-medium text-ink-400">Action</th>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Admin</th>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Details</th>
                <th className="px-4 py-3 text-left font-medium text-ink-400">When</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-ink-800">
              {items.map((item) => (
                <tr key={item.id} className="transition-colors hover:bg-ink-800/60">
                  <td className="px-4 py-3 font-medium text-white">
                    {ACTION_LABELS[item.action] || item.action}
                  </td>
                  <td className="px-4 py-3 text-ink-300">{item.adminEmail || '—'}</td>
                  <td className="px-4 py-3 text-ink-400">
                    {Object.entries(item.details || {})
                      .map(([k, v]) => `${k}: ${v}`)
                      .join(', ') || '—'}
                  </td>
                  <td className="px-4 py-3 text-ink-500">{fmt(item.at)}</td>
                </tr>
              ))}
              {items.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-4 py-10 text-center text-ink-500">
                    No admin actions logged yet.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        </div>
      )}
    </div>
  )
}
