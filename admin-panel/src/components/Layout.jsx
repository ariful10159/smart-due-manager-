import { useEffect, useState } from 'react'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const navItems = [
  { to: '/dashboard', label: 'Dashboard', icon: '📊' },
  { to: '/users', label: 'Users', icon: '👥' },
  { to: '/search', label: 'Search', icon: '🔍' },
  { to: '/announcement', label: 'Announcements', icon: '📣' },
  { to: '/problem-reports', label: 'Problem Reports', icon: '🐞' },
  { to: '/app-config', label: 'App Config', icon: '⚙️' },
  { to: '/admins', label: 'Admins', icon: '🛡️' },
  { to: '/audit-log', label: 'Audit log', icon: '📜' },
]

export default function Layout() {
  const { user, signOut } = useAuth()
  const location = useLocation()
  const [sidebarOpen, setSidebarOpen] = useState(false)

  // Close the mobile drawer whenever the route changes.
  useEffect(() => {
    setSidebarOpen(false)
  }, [location.pathname])

  const currentLabel = navItems.find((item) => location.pathname.startsWith(item.to))?.label || 'Smart Due'

  return (
    <div className="flex h-screen bg-ink-950 text-white">
      {sidebarOpen && (
        <div
          onClick={() => setSidebarOpen(false)}
          className="fixed inset-0 z-30 bg-black/60 backdrop-blur-sm lg:hidden"
        />
      )}

      <aside
        className={`fixed inset-y-0 left-0 z-40 flex w-64 shrink-0 -translate-x-full transform flex-col border-r border-ink-800 bg-ink-900/95 backdrop-blur transition-transform duration-200 lg:static lg:translate-x-0 lg:bg-ink-900/60 ${
          sidebarOpen ? 'translate-x-0' : ''
        }`}
      >
        <div className="flex items-center gap-3 border-b border-ink-800 px-4 py-4">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-indigo-500 to-violet-600 text-sm font-bold text-white shadow-glow">
            SD
          </div>
          <div className="min-w-0">
            <p className="text-sm font-semibold text-white">Smart Due</p>
            <p className="truncate text-xs text-ink-400">{user?.email}</p>
          </div>
        </div>
        <nav className="flex-1 space-y-1 overflow-y-auto p-3">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `group flex items-center gap-2.5 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-150 ${
                  isActive
                    ? 'bg-gradient-to-r from-indigo-500/20 to-violet-500/10 text-white shadow-[inset_0_0_0_1px_rgba(99,102,241,0.4)]'
                    : 'text-ink-300 hover:bg-ink-800 hover:text-white'
                }`
              }
            >
              <span className="text-base">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="border-t border-ink-800 p-3">
          <button
            onClick={signOut}
            className="w-full rounded-lg px-3 py-2.5 text-left text-sm font-medium text-ink-300 transition-colors hover:bg-ink-800 hover:text-red-400"
          >
            Sign out
          </button>
        </div>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center gap-3 border-b border-ink-800 bg-ink-900/60 px-4 py-3 backdrop-blur lg:hidden">
          <button
            onClick={() => setSidebarOpen(true)}
            aria-label="Open menu"
            className="flex h-9 w-9 items-center justify-center rounded-lg border border-ink-700 text-ink-200 transition-colors hover:border-ink-600 hover:text-white"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
              <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          <p className="text-sm font-semibold text-white">{currentLabel}</p>
        </header>

        <main className="relative flex-1 overflow-y-auto bg-grid-fade">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
