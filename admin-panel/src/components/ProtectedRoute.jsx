import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function ProtectedRoute({ children }) {
  const { user, isAdmin, loading } = useAuth()

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center bg-ink-950">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
      </div>
    )
  }

  if (!user) return <Navigate to="/login" replace />

  if (!isAdmin) {
    return (
      <div className="flex h-screen flex-col items-center justify-center gap-2 bg-ink-950 text-center">
        <p className="text-lg font-semibold text-white">Not authorized</p>
        <p className="text-sm text-ink-300">This account does not have admin access.</p>
      </div>
    )
  }

  return children
}
