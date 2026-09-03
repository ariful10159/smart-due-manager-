import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App.jsx'
import './index.css'
import { Sentry } from './sentry.js'

function ErrorFallback() {
  return (
    <div className="flex h-screen flex-col items-center justify-center gap-3 bg-ink-950 p-6 text-center text-white">
      <p className="text-lg font-semibold">Something went wrong.</p>
      <p className="text-sm text-ink-400">The error has been reported. Try reloading the page.</p>
      <button
        onClick={() => window.location.reload()}
        className="rounded-lg border border-ink-700 bg-ink-850 px-4 py-2 text-sm font-medium text-ink-200 hover:border-ink-600 hover:text-white"
      >
        Reload
      </button>
    </div>
  )
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Sentry.ErrorBoundary fallback={<ErrorFallback />}>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </Sentry.ErrorBoundary>
  </React.StrictMode>,
)
