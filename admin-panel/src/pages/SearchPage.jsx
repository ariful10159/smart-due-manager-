import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { fetchUsers, fetchAllCustomers } from '../lib/adminApi'
import LoadError from '../components/LoadError'

const currency = (n) => `৳${Math.round(n || 0).toLocaleString('en-US')}`
const PAGE_SIZE = 50

export default function SearchPage() {
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState('')
  const [customers, setCustomers] = useState([])
  const [ownerMap, setOwnerMap] = useState(new Map())
  const [term, setTerm] = useState('')
  const [visibleCount, setVisibleCount] = useState(PAGE_SIZE)

  useEffect(() => {
    load()
  }, [])

  useEffect(() => {
    setVisibleCount(PAGE_SIZE)
  }, [term])

  async function load() {
    setLoading(true)
    setLoadError('')
    try {
      const [users, allCustomers] = await Promise.all([fetchUsers(), fetchAllCustomers()])
      setOwnerMap(new Map(users.map((u) => [u.id, u])))
      setCustomers(allCustomers)
    } catch (e) {
      setLoadError(e.message || 'Could not load search data.')
    } finally {
      setLoading(false)
    }
  }

  const allMatches = useMemo(() => {
    const q = term.trim().toLowerCase()
    if (!q) return []
    return customers.filter(
      (c) => (c.name || '').toLowerCase().includes(q) || (c.phone || '').toLowerCase().includes(q),
    )
  }, [customers, term])

  const results = allMatches.slice(0, visibleCount)

  return (
    <div className="p-6 md:p-8">
      <h1 className="text-xl font-semibold text-white">Search</h1>
      <p className="mt-1 text-sm text-ink-400">
        Find any customer across every shopkeeper's ledger, by name or phone number.
      </p>

      <input
        autoFocus
        value={term}
        onChange={(e) => setTerm(e.target.value)}
        placeholder="Search by customer name or phone…"
        className="mt-5 w-full max-w-lg rounded-lg border border-ink-700 bg-ink-850 px-4 py-3 text-sm text-white placeholder:text-ink-400 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
      />

      {loading ? (
        <div className="mt-8 flex h-24 items-center justify-center">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
        </div>
      ) : loadError ? (
        <LoadError message={loadError} onRetry={load} />
      ) : term.trim() ? (
        <div className="mt-5 overflow-hidden rounded-2xl border border-ink-800 bg-ink-900/60 shadow-card">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-ink-800 text-sm">
            <thead className="bg-ink-850/80">
              <tr>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Customer</th>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Phone</th>
                <th className="px-4 py-3 text-right font-medium text-ink-400">Due</th>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Belongs to</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-ink-800">
              {results.map((c) => {
                const owner = ownerMap.get(c.ownerId)
                return (
                  <tr key={c.id} className="transition-colors hover:bg-ink-800/60">
                    <td className="px-4 py-3 font-medium text-white">{c.name}</td>
                    <td className="px-4 py-3 text-ink-200">{c.phone || '—'}</td>
                    <td className="px-4 py-3 text-right text-amber-400">{currency(c.totalDue)}</td>
                    <td className="px-4 py-3">
                      <Link
                        to={`/users/${c.ownerId}`}
                        className="font-medium text-indigo-400 transition-colors hover:text-indigo-300"
                      >
                        {owner?.name || owner?.phone || 'Unknown user'}
                      </Link>
                    </td>
                  </tr>
                )
              })}
              {results.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-4 py-10 text-center text-ink-500">
                    No matching customers.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        </div>
      ) : null}

      {!loading && !loadError && term.trim() && allMatches.length > results.length && (
        <div className="mt-3 flex items-center justify-between text-sm text-ink-400">
          <p>
            Showing {results.length} of {allMatches.length} matches
          </p>
          <button
            onClick={() => setVisibleCount((c) => c + PAGE_SIZE)}
            className="rounded-lg border border-ink-700 bg-ink-850 px-3 py-1.5 font-medium text-ink-200 transition-colors hover:border-ink-600 hover:text-white"
          >
            Load more
          </button>
        </div>
      )}

      {!loading && !loadError && !term.trim() && (
        <p className="mt-8 text-sm text-ink-500">Start typing to search across every customer.</p>
      )}
    </div>
  )
}
