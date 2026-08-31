import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { fetchUsers, fetchAllCustomers } from '../lib/adminApi'
import { toCsv, downloadCsv } from '../lib/csv'

const currency = (n) => `৳${Math.round(n || 0).toLocaleString('en-US')}`

const SORT_OPTIONS = [
  { value: 'created_desc', label: 'Newest first' },
  { value: 'created_asc', label: 'Oldest first' },
  { value: 'name_asc', label: 'Name (A–Z)' },
  { value: 'due_desc', label: 'Highest due' },
  { value: 'customers_desc', label: 'Most customers' },
]

export default function UsersListPage() {
  const [users, setUsers] = useState([])
  const [statsByOwner, setStatsByOwner] = useState(new Map())
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all') // all | active | disabled
  const [sort, setSort] = useState('created_desc')

  useEffect(() => {
    load()
  }, [])

  async function load() {
    setLoading(true)
    const [u, allCustomers] = await Promise.all([fetchUsers(), fetchAllCustomers()])
    const stats = new Map()
    allCustomers.forEach((c) => {
      const s = stats.get(c.ownerId) || { count: 0, due: 0 }
      s.count += 1
      s.due += c.totalDue || 0
      stats.set(c.ownerId, s)
    })
    setUsers(u)
    setStatsByOwner(stats)
    setLoading(false)
  }

  const rows = useMemo(() => {
    let list = users.map((u) => ({
      ...u,
      customerCount: statsByOwner.get(u.id)?.count || 0,
      totalDue: statsByOwner.get(u.id)?.due || 0,
      businessName: u.settings?.businessName || '',
    }))

    const term = search.trim().toLowerCase()
    if (term) {
      list = list.filter(
        (u) =>
          (u.name || '').toLowerCase().includes(term) ||
          (u.phone || '').toLowerCase().includes(term) ||
          u.businessName.toLowerCase().includes(term),
      )
    }

    if (statusFilter !== 'all') {
      list = list.filter((u) => (statusFilter === 'disabled' ? !!u.disabled : !u.disabled))
    }

    const [key, dir] = sort.split('_')
    list = [...list].sort((a, b) => {
      let diff = 0
      if (key === 'created') diff = (a.createdAt?.toMillis?.() || 0) - (b.createdAt?.toMillis?.() || 0)
      else if (key === 'name') diff = (a.name || '').localeCompare(b.name || '')
      else if (key === 'due') diff = a.totalDue - b.totalDue
      else if (key === 'customers') diff = a.customerCount - b.customerCount
      return dir === 'asc' ? diff : -diff
    })

    return list
  }, [users, statsByOwner, search, statusFilter, sort])

  const handleExport = () => {
    const csv = toCsv(rows, [
      { label: 'Name', get: (u) => u.name || '' },
      { label: 'Phone', get: (u) => u.phone || '' },
      { label: 'Business Name', get: (u) => u.businessName },
      { label: 'Customers', get: (u) => u.customerCount },
      { label: 'Total Due', get: (u) => u.totalDue },
      { label: 'Status', get: (u) => (u.disabled ? 'Disabled' : 'Active') },
      { label: 'Created', get: (u) => (u.createdAt?.toDate ? u.createdAt.toDate().toISOString() : '') },
      { label: 'UID', get: (u) => u.id },
    ])
    downloadCsv(`smart-due-users-${new Date().toISOString().slice(0, 10)}.csv`, csv)
  }

  return (
    <div className="p-6 md:p-8">
      <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-white">Users</h1>
          <p className="mt-0.5 text-sm text-ink-400">
            {rows.length} of {users.length} registered shopkeepers
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search name, phone, business…"
            className="w-64 rounded-lg border border-ink-700 bg-ink-850 px-3 py-2 text-sm text-white placeholder:text-ink-400 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
          />
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="rounded-lg border border-ink-700 bg-ink-850 px-3 py-2 text-sm text-white outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
          >
            <option value="all">All statuses</option>
            <option value="active">Active</option>
            <option value="disabled">Disabled</option>
          </select>
          <select
            value={sort}
            onChange={(e) => setSort(e.target.value)}
            className="rounded-lg border border-ink-700 bg-ink-850 px-3 py-2 text-sm text-white outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
          >
            {SORT_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
          <button
            onClick={handleExport}
            className="rounded-lg border border-ink-700 bg-ink-850 px-3 py-2 text-sm font-medium text-ink-200 transition-colors hover:border-ink-600 hover:text-white"
          >
            Export CSV
          </button>
        </div>
      </div>

      {loading ? (
        <div className="flex h-40 items-center justify-center">
          <div className="h-7 w-7 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
        </div>
      ) : (
        <div className="overflow-hidden rounded-2xl border border-ink-800 bg-ink-900/60 shadow-card">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-ink-800 text-sm">
            <thead className="bg-ink-850/80">
              <tr>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Name</th>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Business</th>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Phone</th>
                <th className="px-4 py-3 text-right font-medium text-ink-400">Customers</th>
                <th className="px-4 py-3 text-right font-medium text-ink-400">Due</th>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Created</th>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-ink-800">
              {rows.map((u) => (
                <tr key={u.id} className="transition-colors hover:bg-ink-800/60">
                  <td className="px-4 py-3">
                    <Link
                      to={`/users/${u.id}`}
                      className="font-medium text-indigo-400 transition-colors hover:text-indigo-300"
                    >
                      {u.name || '(no name)'}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-ink-300">{u.businessName || '—'}</td>
                  <td className="px-4 py-3 text-ink-200">{u.phone || '—'}</td>
                  <td className="px-4 py-3 text-right text-ink-200">{u.customerCount}</td>
                  <td className="px-4 py-3 text-right text-amber-400">{currency(u.totalDue)}</td>
                  <td className="px-4 py-3 text-ink-400">
                    {u.createdAt?.toDate ? u.createdAt.toDate().toLocaleDateString() : '—'}
                  </td>
                  <td className="px-4 py-3">
                    {u.disabled ? (
                      <span className="rounded-full bg-red-500/10 px-2.5 py-0.5 text-xs font-medium text-red-400 ring-1 ring-inset ring-red-500/30">
                        Disabled
                      </span>
                    ) : (
                      <span className="rounded-full bg-emerald-500/10 px-2.5 py-0.5 text-xs font-medium text-emerald-400 ring-1 ring-inset ring-emerald-500/30">
                        Active
                      </span>
                    )}
                  </td>
                </tr>
              ))}
              {rows.length === 0 && (
                <tr>
                  <td colSpan={7} className="px-4 py-10 text-center text-ink-500">
                    No users found.
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
