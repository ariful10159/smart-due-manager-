import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { fetchAuditLog, fetchUserActivityLog, fetchUsers } from '../lib/adminApi'

const ADMIN_ACTION_LABELS = {
  disable_user: 'Disabled account',
  enable_user: 'Enabled account',
  reset_pin: 'Reset PIN',
  delete_user_data: 'Deleted all user data',
  delete_user_data_failed: 'Failed to delete all user data',
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
  set_admin_role: 'Changed admin role',
  update_problem_report_status: 'Updated problem report status',
}

const USER_ACTION_LABELS = {
  add_customer: 'Added customer',
  edit_customer: 'Edited customer',
  archive_customer: 'Archived customer',
  restore_customer: 'Restored customer',
  delete_customer: 'Deleted customer',
  add_payment: 'Added payment',
}

function fmt(ts) {
  if (!ts?.toDate) return '—'
  return ts.toDate().toLocaleString()
}

export default function AuditLogPage() {
  const [tab, setTab] = useState('admin')
  const [adminItems, setAdminItems] = useState([])
  const [userItems, setUserItems] = useState([])
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    load()
  }, [])

  async function load() {
    setLoading(true)
    // Independent, so one collection's rules not being deployed yet (or any other
    // failure) never blocks the others from loading.
    const [admin, user, allUsers] = await Promise.allSettled([
      fetchAuditLog(),
      fetchUserActivityLog(),
      fetchUsers(),
    ])
    setAdminItems(admin.status === 'fulfilled' ? admin.value : [])
    setUserItems(user.status === 'fulfilled' ? user.value : [])
    setUsers(allUsers.status === 'fulfilled' ? allUsers.value : [])
    setLoading(false)
  }

  const userMap = useMemo(() => new Map(users.map((u) => [u.id, u])), [users])

  return (
    <div className="p-6 md:p-8">
      <h1 className="text-xl font-semibold text-white">Audit log</h1>
      <p className="mt-1 text-sm text-ink-400">Most recent first, up to 200 entries.</p>

      <div className="mt-4 flex gap-2">
        {[
          { value: 'admin', label: 'Admin actions' },
          { value: 'user', label: 'User activity' },
        ].map((t) => (
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
      ) : tab === 'admin' ? (
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
                {adminItems.map((item) => (
                  <tr key={item.id} className="transition-colors hover:bg-ink-800/60">
                    <td className="px-4 py-3 font-medium text-white">
                      {ADMIN_ACTION_LABELS[item.action] || item.action}
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
                {adminItems.length === 0 && (
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
      ) : (
        <div className="mt-5 overflow-hidden rounded-2xl border border-ink-800 bg-ink-900/60 shadow-card">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-ink-800 text-sm">
              <thead className="bg-ink-850/80">
                <tr>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">Action</th>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">User</th>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">Details</th>
                  <th className="px-4 py-3 text-left font-medium text-ink-400">When</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-ink-800">
                {userItems.map((item) => {
                  const user = userMap.get(item.userId)
                  return (
                    <tr key={item.id} className="transition-colors hover:bg-ink-800/60">
                      <td className="px-4 py-3 font-medium text-white">
                        {USER_ACTION_LABELS[item.action] || item.action}
                      </td>
                      <td className="px-4 py-3">
                        {user ? (
                          <Link
                            to={`/users/${item.userId}`}
                            className="font-medium text-indigo-400 transition-colors hover:text-indigo-300"
                          >
                            {user.name || user.phone || item.userId}
                          </Link>
                        ) : (
                          <span className="text-ink-400">{item.userId}</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-ink-400">
                        {Object.entries(item.details || {})
                          .map(([k, v]) => `${k}: ${v}`)
                          .join(', ') || '—'}
                      </td>
                      <td className="px-4 py-3 text-ink-500">{fmt(item.at)}</td>
                    </tr>
                  )
                })}
                {userItems.length === 0 && (
                  <tr>
                    <td colSpan={4} className="px-4 py-10 text-center text-ink-500">
                      No user activity logged yet.
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
