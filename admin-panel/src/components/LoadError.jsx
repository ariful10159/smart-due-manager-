export default function LoadError({ message, onRetry }) {
  return (
    <div className="mt-8 flex flex-col items-center justify-center gap-3 rounded-2xl border border-ink-800 bg-ink-900/60 p-8 text-center">
      <p className="text-sm text-red-400">{message || 'Something went wrong loading this page.'}</p>
      <button
        onClick={onRetry}
        className="rounded-lg border border-ink-700 bg-ink-850 px-4 py-2 text-sm font-medium text-ink-200 transition-colors hover:border-ink-600 hover:text-white"
      >
        Retry
      </button>
    </div>
  )
}
