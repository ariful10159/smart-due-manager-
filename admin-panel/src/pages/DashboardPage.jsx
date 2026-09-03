import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { fetchUsers, fetchAllCustomers, fetchAllNotebooks, fetchAllPayments } from '../lib/adminApi'
import LoadError from '../components/LoadError'

const currency = (n) => `৳${Math.round(n || 0).toLocaleString('en-US')}`
const int = (n) => Math.round(n || 0).toLocaleString('en-US')

const PAYMENT_METHOD_COLORS = {
  bKash: 'bg-pink-500',
  Nagad: 'bg-orange-500',
  'Hand Cash': 'bg-emerald-500',
  Bank: 'bg-sky-500',
  Other: 'bg-ink-500',
}

// Animates a number from 0 up to `target` once, on mount / whenever target changes.
function useCountUp(target, duration = 900) {
  const [value, setValue] = useState(0)

  useEffect(() => {
    let raf
    let start = null
    const from = 0

    const tick = (timestamp) => {
      if (start === null) start = timestamp
      const progress = Math.min((timestamp - start) / duration, 1)
      const eased = 1 - Math.pow(1 - progress, 3)
      setValue(from + (target - from) * eased)
      if (progress < 1) raf = requestAnimationFrame(tick)
    }

    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [target, duration])

  return value
}

function StatCard({ label, value, format = int, sub, accent, delay = 0 }) {
  const animated = useCountUp(value)
  return (
    <div
      className="animate-fadeInUp rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card"
      style={{ animationDelay: `${delay}ms` }}
    >
      <p className="text-xs font-medium uppercase tracking-wide text-ink-400">{label}</p>
      <p className={`mt-2 text-2xl font-semibold tabular-nums ${accent || 'text-white'}`}>{format(animated)}</p>
      {sub && <p className="mt-1 text-xs text-ink-400">{sub}</p>}
    </div>
  )
}

function MonthlySignupsChart({ data, delay = 0 }) {
  const [grown, setGrown] = useState(false)
  useEffect(() => {
    const t = requestAnimationFrame(() => setTimeout(() => setGrown(true), 50))
    return () => cancelAnimationFrame(t)
  }, [])

  const max = Math.max(1, ...data.map((d) => d.count))
  return (
    <div
      className="animate-fadeInUp rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card"
      style={{ animationDelay: `${delay}ms` }}
    >
      <p className="text-sm font-semibold text-white">New signups</p>
      <p className="mt-0.5 text-xs text-ink-400">Last 6 months</p>
      <div className="mt-5 flex items-end gap-4" style={{ height: 140 }}>
        {data.map((d, i) => (
          <div key={d.label} className="flex flex-1 flex-col items-center gap-2">
            <div className="flex h-full w-full items-end justify-center">
              <div
                className="w-8 rounded-t-md bg-gradient-to-t from-indigo-600 to-violet-400 transition-all ease-out"
                style={{
                  height: grown ? `${(d.count / max) * 100}%` : 0,
                  minHeight: grown && d.count > 0 ? 4 : 0,
                  transitionDuration: '600ms',
                  transitionDelay: `${i * 60}ms`,
                }}
                title={`${d.count} new user${d.count === 1 ? '' : 's'}`}
              />
            </div>
            <span className="text-[11px] text-ink-400">{d.label}</span>
            <span className="text-xs font-medium text-ink-200">{d.count}</span>
          </div>
        ))}
      </div>
    </div>
  )
}

function PaymentMethodBreakdown({ data, delay = 0 }) {
  const [grown, setGrown] = useState(false)
  useEffect(() => {
    const t = requestAnimationFrame(() => setTimeout(() => setGrown(true), 50))
    return () => cancelAnimationFrame(t)
  }, [])

  const total = data.reduce((sum, d) => sum + d.amount, 0)
  return (
    <div
      className="animate-fadeInUp rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card"
      style={{ animationDelay: `${delay}ms` }}
    >
      <p className="text-sm font-semibold text-white">Collections by method</p>
      <p className="mt-0.5 text-xs text-ink-400">{currency(total)} collected in total</p>
      <div className="mt-5 space-y-3">
        {data.map((d, i) => {
          const pct = total > 0 ? (d.amount / total) * 100 : 0
          return (
            <div key={d.method}>
              <div className="mb-1 flex items-center justify-between text-xs">
                <span className="font-medium text-ink-200">{d.method}</span>
                <span className="text-ink-400">{currency(d.amount)}</span>
              </div>
              <div className="h-2 w-full overflow-hidden rounded-full bg-ink-800">
                <div
                  className={`h-full rounded-full ${PAYMENT_METHOD_COLORS[d.method] || 'bg-ink-500'} transition-all ease-out`}
                  style={{
                    width: grown ? `${pct}%` : 0,
                    transitionDuration: '700ms',
                    transitionDelay: `${i * 80}ms`,
                  }}
                />
              </div>
            </div>
          )
        })}
        {total === 0 && <p className="text-sm text-ink-500">No payments recorded yet.</p>}
      </div>
    </div>
  )
}

const VERSION_BAR_COLORS = ['bg-indigo-500', 'bg-violet-500', 'bg-sky-500', 'bg-emerald-500', 'bg-amber-500', 'bg-pink-500']

// users.appVersion/platform is stamped by the Flutter app on open (throttled to once/day,
// see lib/services/app_version_report_service.dart) — this is what tells you, before
// flipping on Force Update in App Config, whether that would block 10 people or 1000.
function AppVersionBreakdown({ data, unreportedCount, delay = 0 }) {
  const [grown, setGrown] = useState(false)
  useEffect(() => {
    const t = requestAnimationFrame(() => setTimeout(() => setGrown(true), 50))
    return () => cancelAnimationFrame(t)
  }, [])

  const total = data.reduce((sum, d) => sum + d.count, 0)
  return (
    <div
      className="animate-fadeInUp rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card"
      style={{ animationDelay: `${delay}ms` }}
    >
      <p className="text-sm font-semibold text-white">App versions</p>
      <p className="mt-0.5 text-xs text-ink-400">
        {total} user{total === 1 ? '' : 's'} reporting a version
        {unreportedCount > 0 ? ` · ${unreportedCount} not reported yet` : ''}
      </p>
      <div className="mt-5 space-y-3">
        {data.map((d, i) => {
          const pct = total > 0 ? (d.count / total) * 100 : 0
          return (
            <div key={d.version}>
              <div className="mb-1 flex items-center justify-between text-xs">
                <span className="font-medium text-ink-200">{d.version}</span>
                <span className="text-ink-400">
                  {d.count} ({Math.round(pct)}%)
                </span>
              </div>
              <div className="h-2 w-full overflow-hidden rounded-full bg-ink-800">
                <div
                  className={`h-full rounded-full ${VERSION_BAR_COLORS[i % VERSION_BAR_COLORS.length]} transition-all ease-out`}
                  style={{
                    width: grown ? `${pct}%` : 0,
                    transitionDuration: '700ms',
                    transitionDelay: `${i * 80}ms`,
                  }}
                />
              </div>
            </div>
          )
        })}
        {data.length === 0 && (
          <p className="text-sm text-ink-500">
            No version data yet — this fills in as users open a build that reports its version.
          </p>
        )}
      </div>
    </div>
  )
}

export default function DashboardPage() {
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState('')
  const [users, setUsers] = useState([])
  const [customers, setCustomers] = useState([])
  const [notebookCount, setNotebookCount] = useState(0)
  const [payments, setPayments] = useState([])

  useEffect(() => {
    load()
  }, [])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      const [u, c, n] = await Promise.all([fetchUsers(), fetchAllCustomers(), fetchAllNotebooks()])
      const p = await fetchAllPayments(c.map((customer) => customer.id))
      setUsers(u)
      setCustomers(c)
      setNotebookCount(n.length)
      setPayments(p)
    } catch (e) {
      setLoadError(e.message || 'Could not load dashboard data.')
    } finally {
      setLoading(false)
    }
  }

  const stats = useMemo(() => {
    const activeUsers = users.filter((u) => !u.disabled).length
    const disabledUsers = users.length - activeUsers
    const totalDue = customers.reduce((sum, c) => sum + (c.totalDue || 0), 0)
    const totalCollected = payments
      .filter((p) => p.type === 'payment')
      .reduce((sum, p) => sum + (p.amount || 0), 0)
    return { activeUsers, disabledUsers, totalDue, totalCollected }
  }, [users, customers, payments])

  const monthlySignups = useMemo(() => {
    const now = new Date()
    const months = []
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
      months.push({ key: `${d.getFullYear()}-${d.getMonth()}`, label: d.toLocaleString('en-US', { month: 'short' }), count: 0 })
    }
    users.forEach((u) => {
      const created = u.createdAt?.toDate ? u.createdAt.toDate() : null
      if (!created) return
      const key = `${created.getFullYear()}-${created.getMonth()}`
      const bucket = months.find((m) => m.key === key)
      if (bucket) bucket.count += 1
    })
    return months
  }, [users])

  const paymentMethodBreakdown = useMemo(() => {
    const totals = { bKash: 0, Nagad: 0, 'Hand Cash': 0, Bank: 0, Other: 0 }
    payments
      .filter((p) => p.type === 'payment')
      .forEach((p) => {
        const key = totals[p.paymentMethod] !== undefined ? p.paymentMethod : 'Other'
        totals[key] += p.amount || 0
      })
    return Object.entries(totals)
      .map(([method, amount]) => ({ method, amount }))
      .filter((d) => d.amount > 0 || d.method !== 'Other')
  }, [payments])

  const appVersionBreakdown = useMemo(() => {
    const counts = new Map()
    let unreported = 0
    users.forEach((u) => {
      if (!u.appVersion) {
        unreported += 1
        return
      }
      counts.set(u.appVersion, (counts.get(u.appVersion) || 0) + 1)
    })
    const data = [...counts.entries()]
      .map(([version, count]) => ({ version, count }))
      .sort((a, b) => b.count - a.count)
    return { data, unreported }
  }, [users])

  const recentUsers = useMemo(() => {
    return [...users]
      .sort((a, b) => (b.createdAt?.toMillis?.() || 0) - (a.createdAt?.toMillis?.() || 0))
      .slice(0, 5)
  }, [users])

  const topDueCustomers = useMemo(() => {
    const ownerName = new Map(users.map((u) => [u.id, u.name || u.phone || 'Unknown']))
    return [...customers]
      .filter((c) => (c.totalDue || 0) > 0)
      .sort((a, b) => (b.totalDue || 0) - (a.totalDue || 0))
      .slice(0, 5)
      .map((c) => ({ ...c, ownerName: ownerName.get(c.ownerId) || 'Unknown' }))
  }, [customers, users])

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-7 w-7 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
      </div>
    )
  }

  if (loadError) {
    return (
      <div className="p-6 md:p-8">
        <h1 className="text-xl font-semibold text-white">Dashboard</h1>
        <LoadError message={loadError} onRetry={load} />
      </div>
    )
  }

  return (
    <div className="p-6 md:p-8">
      <h1 className="text-xl font-semibold text-white">Dashboard</h1>
      <p className="mt-1 text-sm text-ink-400">Full overview of Smart Due Manager, across every shopkeeper.</p>

      <div className="mt-6 grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-5">
        <StatCard
          label="Users"
          value={users.length}
          sub={`${stats.activeUsers} active · ${stats.disabledUsers} disabled`}
          delay={0}
        />
        <StatCard label="Customers" value={customers.length} delay={60} />
        <StatCard label="Notebooks" value={notebookCount} delay={120} />
        <StatCard label="Outstanding due" value={stats.totalDue} format={currency} accent="text-amber-400" delay={180} />
        <StatCard
          label="Total collected"
          value={stats.totalCollected}
          format={currency}
          accent="text-emerald-400"
          delay={240}
        />
      </div>

      <div className="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
        <MonthlySignupsChart data={monthlySignups} delay={300} />
        <PaymentMethodBreakdown data={paymentMethodBreakdown} delay={340} />
      </div>

      <div className="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div
          className="animate-fadeInUp overflow-hidden rounded-2xl border border-ink-800 bg-ink-900/60 shadow-card"
          style={{ animationDelay: '380ms' }}
        >
          <div className="border-b border-ink-800 px-5 py-4">
            <p className="text-sm font-semibold text-white">Recent users</p>
          </div>
          <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <tbody className="divide-y divide-ink-800">
              {recentUsers.map((u) => (
                <tr key={u.id} className="transition-colors hover:bg-ink-800/60">
                  <td className="px-5 py-3">
                    <Link to={`/users/${u.id}`} className="font-medium text-indigo-400 hover:text-indigo-300">
                      {u.name || '(no name)'}
                    </Link>
                  </td>
                  <td className="px-5 py-3 text-ink-400">{u.phone || '—'}</td>
                  <td className="px-5 py-3 text-right text-ink-400">
                    {u.createdAt?.toDate ? u.createdAt.toDate().toLocaleDateString() : '—'}
                  </td>
                </tr>
              ))}
              {recentUsers.length === 0 && (
                <tr>
                  <td className="px-5 py-8 text-center text-ink-500">No users yet.</td>
                </tr>
              )}
            </tbody>
          </table>
          </div>
        </div>

        <div
          className="animate-fadeInUp overflow-hidden rounded-2xl border border-ink-800 bg-ink-900/60 shadow-card"
          style={{ animationDelay: '420ms' }}
        >
          <div className="border-b border-ink-800 px-5 py-4">
            <p className="text-sm font-semibold text-white">Top due customers</p>
          </div>
          <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <tbody className="divide-y divide-ink-800">
              {topDueCustomers.map((c) => (
                <tr key={c.id} className="transition-colors hover:bg-ink-800/60">
                  <td className="px-5 py-3">
                    <Link to={`/users/${c.ownerId}`} className="font-medium text-white hover:text-indigo-300">
                      {c.name}
                    </Link>
                    <p className="text-xs text-ink-400">{c.ownerName}</p>
                  </td>
                  <td className="px-5 py-3 text-right font-medium text-amber-400">{currency(c.totalDue)}</td>
                </tr>
              ))}
              {topDueCustomers.length === 0 && (
                <tr>
                  <td className="px-5 py-8 text-center text-ink-500">No outstanding dues 🎉</td>
                </tr>
              )}
            </tbody>
          </table>
          </div>
        </div>
      </div>

      <div className="mt-6">
        <AppVersionBreakdown
          data={appVersionBreakdown.data}
          unreportedCount={appVersionBreakdown.unreported}
          delay={460}
        />
      </div>
    </div>
  )
}
