import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { fetchUsers, fetchAppConfig } from '../lib/adminApi'
import { toCsv, downloadCsv } from '../lib/csv'

function fmt(ts) {
  if (!ts?.toDate) return '—'
  return ts.toDate().toLocaleString()
}

function StatusBadge({ accepted, current }) {
  if (!current) {
    return <span className="rounded-full bg-ink-700 px-2 py-0.5 text-xs font-medium text-ink-400">N/A</span>
  }
  if (!accepted) {
    return (
      <span className="rounded-full bg-red-500/10 px-2 py-0.5 text-xs font-medium text-red-400 ring-1 ring-inset ring-red-500/30">
        Never accepted
      </span>
    )
  }
  if (accepted < current) {
    return (
      <span className="rounded-full bg-amber-500/10 px-2 py-0.5 text-xs font-medium text-amber-400 ring-1 ring-inset ring-amber-500/30">
        Outdated (v{accepted})
      </span>
    )
  }
  return (
    <span className="rounded-full bg-emerald-500/10 px-2 py-0.5 text-xs font-medium text-emerald-400 ring-1 ring-inset ring-emerald-500/30">
      Up to date (v{accepted})
    </span>
  )
}

export default function PolicyAcceptancePage() {
  const [users, setUsers] = useState([])
  const [config, setConfig] = useState(null)
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [onlyOutdated, setOnlyOutdated] = useState(false)

  useEffect(() => {
    load()
  }, [])

  async function load() {
    setLoading(true)
    const [u, c] = await Promise.all([fetchUsers(), fetchAppConfig()])
    setUsers(u)
    setConfig(c)
    setLoading(false)
  }

  const currentPrivacy = config?.privacyVersion || 0
  const currentTerms = config?.termsVersion || 0

  const rows = useMemo(() => {
    let list = users.map((u) => ({
      ...u,
      privacyOutdated: currentPrivacy > 0 && (u.acceptedPrivacyVersion || 0) < currentPrivacy,
      termsOutdated: currentTerms > 0 && (u.acceptedTermsVersion || 0) < currentTerms,
    }))

    const term = search.trim().toLowerCase()
    if (term) {
      list = list.filter(
        (u) => (u.name || '').toLowerCase().includes(term) || (u.phone || '').toLowerCase().includes(term),
      )
    }

    if (onlyOutdated) {
      list = list.filter((u) => u.privacyOutdated || u.termsOutdated)
    }

    return list
  }, [users, search, onlyOutdated, currentPrivacy, currentTerms])

  const handleExport = () => {
    const csv = toCsv(rows, [
      { label: 'Name', get: (u) => u.name || '' },
      { label: 'Phone', get: (u) => u.phone || '' },
      { label: 'Privacy version accepted', get: (u) => u.acceptedPrivacyVersion ?? '' },
      { label: 'Privacy accepted at', get: (u) => (u.acceptedPrivacyAt?.toDate ? u.acceptedPrivacyAt.toDate().toISOString() : '') },
      { label: 'Terms version accepted', get: (u) => u.acceptedTermsVersion ?? '' },
      { label: 'Terms accepted at', get: (u) => (u.acceptedTermsAt?.toDate ? u.acceptedTermsAt.toDate().toISOString() : '') },
    ])
    downloadCsv(csv, 'policy-acceptance.csv')
  }

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-7 w-7 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
      </div>
    )
  }

  const outdatedCount = users.filter(
    (u) =>
      (currentPrivacy > 0 && (u.acceptedPrivacyVersion || 0) < currentPrivacy) ||
      (currentTerms > 0 && (u.acceptedTermsVersion || 0) < currentTerms),
  ).length

  return (
    <div className="max-w-5xl p-6 md:p-8">
      <Link to="/app-config" className="text-sm font-medium text-indigo-400 transition-colors hover:text-indigo-300">
        ← App Config
      </Link>
      <div className="mt-2 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-white">Policy Acceptance</h1>
          <p className="mt-1 text-sm text-ink-400">
            Current published versions: Privacy v{currentPrivacy || '—'} · Terms v{currentTerms || '—'}. Kept for
            legal/compliance records — who accepted which version, and when.
          </p>
        </div>
        <button
          onClick={handleExport}
          className="rounded-lg border border-ink-700 px-3 py-1.5 text-sm font-medium text-ink-300 transition-colors hover:border-indigo-500 hover:text-white"
        >
          ⬇ Export CSV
        </button>
      </div>

      {outdatedCount > 0 && (
        <div className="mt-4 rounded-lg border border-amber-500/30 bg-amber-500/10 px-3 py-2 text-sm text-amber-300">
          {outdatedCount} user{outdatedCount === 1 ? '' : 's'} haven't accepted the current policy version yet.
          They'll be prompted the next time they open the app.
        </div>
      )}

      <div className="mt-5 flex flex-wrap items-center gap-3">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search name or phone…"
          className="w-full max-w-xs rounded-lg border border-ink-700 bg-ink-850 px-3 py-2 text-sm text-white placeholder:text-ink-400 outline-none focus:border-indigo-500"
        />
        <label className="flex items-center gap-2 text-sm text-ink-300">
          <input
            type="checkbox"
            checked={onlyOutdated}
            onChange={(e) => setOnlyOutdated(e.target.checked)}
            className="h-4 w-4 rounded border-ink-600 bg-ink-850 text-indigo-500 focus:ring-indigo-500 focus:ring-offset-0"
          />
          Only show outdated / not accepted
        </label>
      </div>

      <div className="mt-4 overflow-x-auto rounded-2xl border border-ink-800 bg-ink-900/60 shadow-card">
        <table className="w-full min-w-[640px] text-left text-sm">
          <thead>
            <tr className="border-b border-ink-800 text-xs uppercase tracking-wide text-ink-500">
              <th className="px-4 py-3 font-medium">User</th>
              <th className="px-4 py-3 font-medium">Privacy Policy</th>
              <th className="px-4 py-3 font-medium">Terms &amp; Conditions</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((u) => (
              <tr key={u.id} className="border-b border-ink-800/60 last:border-0">
                <td className="px-4 py-3">
                  <p className="font-medium text-white">{u.name || '(no name)'}</p>
                  <p className="text-xs text-ink-500">{u.phone || '—'}</p>
                </td>
                <td className="px-4 py-3">
                  <StatusBadge accepted={u.acceptedPrivacyVersion} current={currentPrivacy} />
                  <p className="mt-1 text-xs text-ink-500">{fmt(u.acceptedPrivacyAt)}</p>
                </td>
                <td className="px-4 py-3">
                  <StatusBadge accepted={u.acceptedTermsVersion} current={currentTerms} />
                  <p className="mt-1 text-xs text-ink-500">{fmt(u.acceptedTermsAt)}</p>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {rows.length === 0 && <p className="p-8 text-center text-sm text-ink-500">No users match.</p>}
      </div>
    </div>
  )
}
