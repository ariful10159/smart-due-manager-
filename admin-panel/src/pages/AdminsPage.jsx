import { useEffect, useState } from 'react'
import { fetchAdmins, addAdmin, removeAdmin, setAdminRole } from '../lib/adminApi'
import { useAuth } from '../context/AuthContext'
import ConfirmDialog from '../components/ConfirmDialog'

const inputClass =
  'w-full rounded-lg border border-ink-700 bg-ink-850 px-3 py-2 text-sm text-white placeholder:text-ink-400 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500'

const roleOf = (a) => (a.role === 'staff' ? 'staff' : 'super')

const roleBadgeClass = (role) =>
  role === 'super'
    ? 'rounded-full bg-indigo-500/15 px-2 py-0.5 text-xs font-medium text-indigo-300'
    : 'rounded-full bg-ink-700 px-2 py-0.5 text-xs font-medium text-ink-300'

export default function AdminsPage() {
  const { user, isSuperAdmin } = useAuth()
  const [admins, setAdmins] = useState([])
  const [loading, setLoading] = useState(true)
  const [uid, setUid] = useState('')
  const [email, setEmail] = useState('')
  const [role, setRole] = useState('staff')
  const [adding, setAdding] = useState(false)
  const [error, setError] = useState('')
  const [roleError, setRoleError] = useState('')
  const [confirmRemove, setConfirmRemove] = useState(null)
  const [removeError, setRemoveError] = useState('')

  useEffect(() => {
    load()
  }, [])

  async function load() {
    setLoading(true)
    setAdmins(await fetchAdmins())
    setLoading(false)
  }

  if (!isSuperAdmin) {
    return (
      <div className="flex h-64 flex-col items-center justify-center gap-2 p-6 text-center">
        <p className="text-lg font-semibold text-white">Not authorized</p>
        <p className="text-sm text-ink-300">Only super admins can manage admin access.</p>
      </div>
    )
  }

  const handleAdd = async (e) => {
    e.preventDefault()
    setError('')
    if (!uid.trim()) {
      setError('UID is required.')
      return
    }
    setAdding(true)
    try {
      await addAdmin(uid.trim(), email.trim() || null, role)
      setUid('')
      setEmail('')
      setRole('staff')
      await load()
    } catch (e) {
      setError(e.message || 'Could not add admin. Double-check the UID.')
    } finally {
      setAdding(false)
    }
  }

  const handleRoleChange = async (admin, newRole) => {
    setRoleError('')
    try {
      await setAdminRole(admin.id, newRole)
      await load()
    } catch (e) {
      setRoleError(e.message || 'Could not change this admin’s role.')
    }
  }

  return (
    <div className="max-w-2xl p-6 md:p-8">
      <h1 className="text-xl font-semibold text-white">Admins</h1>
      <p className="mt-1 text-sm text-ink-400">
        Anyone listed here can sign in to this admin panel. <span className="text-ink-300">Super</span> admins can
        additionally manage other admins and delete a user's entire data. The Firebase Auth account itself must
        already exist (Console → Authentication → Add user) before granting admin here.
      </p>

      <form onSubmit={handleAdd} className="mt-5 rounded-2xl border border-ink-800 bg-ink-900/60 p-5 shadow-card">
        <p className="text-sm font-semibold text-white">Grant admin access</p>
        <div className="mt-3 grid grid-cols-1 gap-3 sm:grid-cols-2">
          <input
            value={uid}
            onChange={(e) => setUid(e.target.value)}
            placeholder="Firebase Auth UID"
            className={inputClass}
          />
          <input
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Email (for display only)"
            className={inputClass}
          />
          <select value={role} onChange={(e) => setRole(e.target.value)} className={inputClass}>
            <option value="staff">Staff — everything except managing admins / deleting users</option>
            <option value="super">Super — full access</option>
          </select>
        </div>
        {error && <p className="mt-2 text-sm text-red-400">{error}</p>}
        <button
          type="submit"
          disabled={adding}
          className="mt-3 rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-4 py-2 text-sm font-medium text-white shadow-glow transition-transform hover:scale-[1.02] disabled:opacity-60"
        >
          {adding ? 'Adding…' : 'Add admin'}
        </button>
      </form>

      {roleError && <p className="mt-3 text-sm text-red-400">{roleError}</p>}

      {loading ? (
        <div className="mt-6 flex h-24 items-center justify-center">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
        </div>
      ) : (
        <div className="mt-6 overflow-hidden rounded-2xl border border-ink-800 bg-ink-900/60 shadow-card">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-ink-800 text-sm">
            <thead className="bg-ink-850/80">
              <tr>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Email</th>
                <th className="px-4 py-3 text-left font-medium text-ink-400">UID</th>
                <th className="px-4 py-3 text-left font-medium text-ink-400">Role</th>
                <th className="px-4 py-3"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-ink-800">
              {admins.map((a) => (
                <tr key={a.id} className="transition-colors hover:bg-ink-800/60">
                  <td className="px-4 py-3 text-white">
                    {a.email || '—'} {a.id === user?.uid && <span className="text-ink-500">(you)</span>}
                  </td>
                  <td className="px-4 py-3 font-mono text-xs text-ink-400">{a.id}</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <span className={roleBadgeClass(roleOf(a))}>{roleOf(a) === 'super' ? 'Super' : 'Staff'}</span>
                      <button
                        onClick={() => handleRoleChange(a, roleOf(a) === 'super' ? 'staff' : 'super')}
                        className="text-xs font-medium text-ink-400 underline-offset-2 transition-colors hover:text-white hover:underline"
                      >
                        Make {roleOf(a) === 'super' ? 'staff' : 'super'}
                      </button>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() => {
                        setRemoveError('')
                        setConfirmRemove(a)
                      }}
                      className="text-sm font-medium text-red-400 transition-colors hover:text-red-300"
                    >
                      Remove
                    </button>
                  </td>
                </tr>
              ))}
              {admins.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-4 py-10 text-center text-ink-500">
                    No admins found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        </div>
      )}

      {removeError && <p className="mt-3 text-sm text-red-400">{removeError}</p>}

      <ConfirmDialog
        open={!!confirmRemove}
        title="Remove admin access?"
        message={
          confirmRemove?.id === user?.uid
            ? 'This is your own account — removing it will lock you out of this admin panel immediately.'
            : `${confirmRemove?.email || confirmRemove?.id} will no longer be able to access this admin panel.`
        }
        confirmLabel="Remove"
        onCancel={() => setConfirmRemove(null)}
        onConfirm={async () => {
          try {
            await removeAdmin(confirmRemove.id)
            setConfirmRemove(null)
            await load()
          } catch (e) {
            setRemoveError(e.message || 'Could not remove this admin.')
            setConfirmRemove(null)
          }
        }}
      />
    </div>
  )
}
