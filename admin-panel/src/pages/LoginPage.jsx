import { useState } from 'react'
import { useNavigate, Navigate } from 'react-router-dom'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { auth } from '../firebase'
import { useAuth } from '../context/AuthContext'

export default function LoginPage() {
  const { user, loading } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  if (!loading && user) return <Navigate to="/dashboard" replace />

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      await signInWithEmailAndPassword(auth, email.trim(), password)
      navigate('/dashboard')
    } catch {
      setError('Login failed. Check email/password.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="relative flex h-screen items-center justify-center overflow-hidden bg-ink-950 p-4">
      <div className="pointer-events-none absolute -left-24 -top-24 h-72 w-72 animate-blob rounded-full bg-indigo-600/30 blur-3xl" />
      <div className="pointer-events-none absolute -right-16 top-1/3 h-72 w-72 animate-blob rounded-full bg-violet-600/20 blur-3xl [animation-delay:4s]" />
      <div className="pointer-events-none absolute bottom-[-6rem] left-1/3 h-72 w-72 animate-blob rounded-full bg-fuchsia-600/15 blur-3xl [animation-delay:8s]" />

      <form
        onSubmit={handleSubmit}
        className="relative z-10 w-full max-w-sm rounded-2xl border border-ink-700 bg-ink-900/80 p-7 shadow-card backdrop-blur-xl animate-fadeIn"
      >
        <div className="mb-6 flex flex-col items-center text-center">
          <div className="mb-3 flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br from-indigo-500 to-violet-600 text-base font-bold text-white shadow-glow">
            SD
          </div>
          <h1 className="text-lg font-semibold text-white">Smart Due — Admin</h1>
          <p className="mt-1 text-xs text-ink-400">Sign in with your admin account</p>
        </div>

        <div className="space-y-3">
          <input
            type="email"
            required
            placeholder="Admin email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full rounded-lg border border-ink-700 bg-ink-850 px-3 py-2.5 text-sm text-white placeholder:text-ink-400 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
          />
          <input
            type="password"
            required
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full rounded-lg border border-ink-700 bg-ink-850 px-3 py-2.5 text-sm text-white placeholder:text-ink-400 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
          />
        </div>

        {error && <p className="mt-3 text-sm text-red-400">{error}</p>}

        <button
          type="submit"
          disabled={submitting}
          className="mt-5 w-full rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-3 py-2.5 text-sm font-medium text-white shadow-glow transition-transform duration-150 hover:scale-[1.02] active:scale-[0.99] disabled:opacity-60 disabled:hover:scale-100"
        >
          {submitting ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
    </div>
  )
}
