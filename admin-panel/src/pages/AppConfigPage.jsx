import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  fetchAppConfig,
  updateAppConfig,
  fetchVersionHistory,
  publishVersion,
  fetchPolicyHistory,
  publishPolicy,
} from '../lib/adminApi'
import Modal from '../components/Modal'
import Toggle from '../components/Toggle'
import PhonePreview from '../components/PhonePreview'

const inputClass =
  'w-full rounded-lg border border-ink-700 bg-ink-850 px-3 py-2.5 text-sm text-white placeholder:text-ink-400 outline-none transition-colors focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500'

const labelClass = 'mb-1 flex items-center gap-1.5 text-xs font-medium text-ink-400'

const DURATION_PRESETS = [
  { label: '30 min', ms: 30 * 60 * 1000 },
  { label: '1 hr', ms: 60 * 60 * 1000 },
  { label: '2 hr', ms: 2 * 60 * 60 * 1000 },
  { label: '4 hr', ms: 4 * 60 * 60 * 1000 },
  { label: '1 day', ms: 24 * 60 * 60 * 1000 },
]

function fmt(ts) {
  if (!ts) return '—'
  if (ts.toDate) return ts.toDate().toLocaleString()
  if (ts instanceof Date) return ts.toLocaleString()
  return '—'
}

// "1.2.3" style comparison — true if [a] is strictly below [b]. Missing parts count as 0.
function isVersionBelow(a, b) {
  const pa = a.trim().split('.').map((n) => parseInt(n, 10) || 0)
  const pb = b.trim().split('.').map((n) => parseInt(n, 10) || 0)
  const len = Math.max(pa.length, pb.length)
  for (let i = 0; i < len; i++) {
    const x = pa[i] || 0
    const y = pb[i] || 0
    if (x !== y) return x < y
  }
  return false
}

function formatRemaining(until) {
  if (!until) return null
  const diffMs = until.getTime() - Date.now()
  const abs = Math.abs(diffMs)
  const h = Math.floor(abs / 3600000)
  const m = Math.floor((abs % 3600000) / 60000)
  const text = h > 0 ? `${h}h ${m}m` : `${m}m`
  return diffMs >= 0 ? `${text} remaining` : `${text} ago — ETA has passed`
}

function Badge({ on, onLabel = 'ON', offLabel = 'OFF' }) {
  return on ? (
    <span className="shrink-0 rounded-full bg-emerald-500/10 px-2 py-0.5 text-xs font-medium text-emerald-400 ring-1 ring-inset ring-emerald-500/30">
      {onLabel}
    </span>
  ) : (
    <span className="shrink-0 rounded-full bg-ink-700 px-2 py-0.5 text-xs font-medium text-ink-300">{offLabel}</span>
  )
}

function Banner({ tone = 'warning', children }) {
  const tones = {
    warning: 'border-amber-500/30 bg-amber-500/10 text-amber-300',
    danger: 'border-red-500/30 bg-red-500/10 text-red-300',
    info: 'border-indigo-500/30 bg-indigo-500/10 text-indigo-300',
  }
  return <div className={`rounded-lg border px-3 py-2 text-xs leading-relaxed ${tones[tone]}`}>{children}</div>
}

function ConfigCard({ icon, title, summary, badge, onClick }) {
  return (
    <button
      onClick={onClick}
      className="flex flex-col items-start gap-2 rounded-2xl border border-ink-800 bg-ink-900/60 p-5 text-left shadow-card transition-colors hover:border-ink-600"
    >
      <div className="flex w-full items-center justify-between gap-2">
        <span className="text-2xl">{icon}</span>
        {badge}
      </div>
      <p className="font-semibold text-white">{title}</p>
      <p className="text-sm text-ink-400">{summary}</p>
    </button>
  )
}

function ModalFooter({ onCancel, onSave, saving, dirty, error }) {
  return (
    <div className="mt-5">
      {error && <p className="mb-3 text-sm text-red-400">{error}</p>}
      <div className="flex justify-end gap-2">
        <button
          onClick={onCancel}
          className="rounded-lg px-3 py-1.5 text-sm font-medium text-ink-300 transition-colors hover:bg-ink-700 hover:text-white"
        >
          Cancel
        </button>
        <button
          onClick={onSave}
          disabled={saving || !dirty}
          className="rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-4 py-1.5 text-sm font-medium text-white shadow-glow transition-transform hover:scale-[1.02] disabled:opacity-60 disabled:hover:scale-100"
        >
          {saving ? 'Saving…' : 'Save'}
        </button>
      </div>
    </div>
  )
}

function HistoryTimeline({ items, renderLabel, renderMeta }) {
  if (items.length === 0) return null
  return (
    <div className="mt-5">
      <p className="mb-2 text-xs font-medium text-ink-400">History</p>
      <div className="max-h-40 overflow-y-auto pr-1">
        {items.map((item, i) => (
          <div key={item.id} className="relative flex gap-3 pb-3 last:pb-0">
            <div className="flex flex-col items-center">
              <span className={`mt-1 h-2 w-2 shrink-0 rounded-full ${i === 0 ? 'bg-indigo-400' : 'bg-ink-600'}`} />
              {i !== items.length - 1 && <span className="w-px flex-1 bg-ink-700" />}
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-xs font-medium text-ink-200">{renderLabel(item)}</p>
              <p className="text-[11px] text-ink-500">{renderMeta(item)}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

// ============================================
// App Version
// ============================================

function AppVersionModal({ config, onClose, onSaved }) {
  const [currentVersion, setCurrentVersion] = useState(config.currentVersion || '')
  const [minRequiredVersion, setMinRequiredVersion] = useState(config.minRequiredVersion || '')
  const [playStoreUrl, setPlayStoreUrl] = useState(config.playStoreUrl || '')
  const [history, setHistory] = useState([])
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    fetchVersionHistory().then(setHistory)
  }, [])

  const dirty =
    currentVersion !== (config.currentVersion || '') ||
    minRequiredVersion !== (config.minRequiredVersion || '') ||
    playStoreUrl !== (config.playStoreUrl || '')

  const conflict =
    currentVersion.trim() && minRequiredVersion.trim() && isVersionBelow(currentVersion, minRequiredVersion)

  const handleSave = async () => {
    setSaving(true)
    setError('')
    try {
      await publishVersion({ currentVersion, minRequiredVersion, playStoreUrl })
      onSaved()
    } catch (e) {
      setError(e.message || 'Could not save.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal open title="🏷️ App Version" onClose={onClose}>
      <div className="space-y-4">
        <div>
          <label className={labelClass}>Current version (latest released, informational)</label>
          <input
            value={currentVersion}
            onChange={(e) => setCurrentVersion(e.target.value)}
            placeholder="1.2.0"
            className={inputClass}
          />
        </div>
        <div>
          <label className={labelClass}>Minimum required version (used by Force Update)</label>
          <input
            value={minRequiredVersion}
            onChange={(e) => setMinRequiredVersion(e.target.value)}
            placeholder="1.0.0"
            className={inputClass}
          />
        </div>
        <div>
          <label className={labelClass}>Play Store URL (shown on the force-update screen)</label>
          <input
            value={playStoreUrl}
            onChange={(e) => setPlayStoreUrl(e.target.value)}
            placeholder="https://play.google.com/store/apps/details?id=..."
            className={inputClass}
          />
        </div>

        {conflict && (
          <Banner tone="danger">
            ⚠️ Current version ({currentVersion}) is below the minimum required version ({minRequiredVersion}).
            If Force Update is on, this would block everyone — including anyone already on the latest release.
          </Banner>
        )}

        <HistoryTimeline
          items={history}
          renderLabel={(h) => (
            <>
              {h.currentVersion} <span className="text-ink-500">(min {h.minRequiredVersion})</span>
            </>
          )}
          renderMeta={(h) => `${fmt(h.changedAt)} · ${h.changedBy || 'unknown'}`}
        />
      </div>
      <ModalFooter onCancel={onClose} onSave={handleSave} saving={saving} dirty={dirty} error={error} />
    </Modal>
  )
}

// ============================================
// Maintenance Mode
// ============================================

function MaintenanceModal({ config, onClose, onSaved }) {
  const [enabled, setEnabled] = useState(config.maintenanceEnabled || false)
  const [message, setMessage] = useState(config.maintenanceMessage || '')
  const [until, setUntil] = useState(config.maintenanceUntil?.toDate ? config.maintenanceUntil.toDate() : null)
  const [saving, setSaving] = useState(false)
  const [, setTick] = useState(0)

  // Re-render every 30s so the "remaining" countdown stays live while the modal is open.
  useEffect(() => {
    const id = setInterval(() => setTick((t) => t + 1), 30000)
    return () => clearInterval(id)
  }, [])

  const initialUntilMs = config.maintenanceUntil?.toDate ? config.maintenanceUntil.toDate().getTime() : null
  const dirty =
    enabled !== (config.maintenanceEnabled || false) ||
    message !== (config.maintenanceMessage || '') ||
    (until?.getTime() ?? null) !== initialUntilMs

  const handleSave = async () => {
    setSaving(true)
    try {
      await updateAppConfig(
        { maintenanceEnabled: enabled, maintenanceMessage: message, maintenanceUntil: until },
        'update_maintenance',
      )
      onSaved()
    } finally {
      setSaving(false)
    }
  }

  const previewMessage = message.trim() || "We're doing some scheduled maintenance. Please check back soon."

  return (
    <Modal open title="🚧 Maintenance Mode" onClose={onClose} wide>
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-[1fr_200px]">
        <div className="space-y-4">
          <div className="rounded-lg border border-ink-700 bg-ink-900/50 p-3">
            <Toggle
              checked={enabled}
              onChange={setEnabled}
              label="Block the app"
              description="Everyone sees the maintenance screen, even before login"
            />
          </div>

          <div>
            <label className={labelClass}>Message shown to users</label>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              rows={3}
              placeholder="We're doing scheduled maintenance. Please check back soon."
              className={inputClass}
            />
          </div>

          <div>
            <p className={labelClass}>Expected back (ETA — display only, doesn't auto turn off)</p>
            <div className="flex flex-wrap gap-2">
              {DURATION_PRESETS.map((p) => (
                <button
                  key={p.label}
                  onClick={() => setUntil(new Date(Date.now() + p.ms))}
                  className="rounded-lg border border-ink-700 px-3 py-1.5 text-xs font-medium text-ink-300 transition-colors hover:border-indigo-500 hover:text-white"
                >
                  {p.label}
                </button>
              ))}
              <button
                onClick={() => setUntil(null)}
                className="rounded-lg border border-ink-700 px-3 py-1.5 text-xs font-medium text-ink-400 transition-colors hover:border-red-500 hover:text-red-400"
              >
                Clear
              </button>
            </div>
            {until && (
              <p className="mt-2 text-xs text-ink-400">
                {until.toLocaleString()} · <span className="text-indigo-300">{formatRemaining(until)}</span>
              </p>
            )}
          </div>
        </div>

        <div>
          <p className={labelClass}>Live preview</p>
          <PhonePreview>
            <span className="text-3xl">🚧</span>
            <p className="text-sm font-bold text-white">Under Maintenance</p>
            <p className="text-xs leading-relaxed text-ink-400">{previewMessage}</p>
            {until && <p className="text-[10px] text-ink-500">Expected back around {until.toLocaleString()}</p>}
          </PhonePreview>
        </div>
      </div>
      <ModalFooter onCancel={onClose} onSave={handleSave} saving={saving} dirty={dirty} />
    </Modal>
  )
}

// ============================================
// Force Update
// ============================================

function ForceUpdateModal({ config, onClose, onSaved, onOpenVersion }) {
  const [enabled, setEnabled] = useState(config.forceUpdateEnabled || false)
  const [saving, setSaving] = useState(false)
  const dirty = enabled !== (config.forceUpdateEnabled || false)
  const minRequiredVersion = (config.minRequiredVersion || '').trim()

  const handleSave = async () => {
    setSaving(true)
    try {
      await updateAppConfig({ forceUpdateEnabled: enabled }, 'update_force_update')
      onSaved()
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal open title="⬆️ Force Update" onClose={onClose} wide>
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-[1fr_200px]">
        <div className="space-y-4">
          <div className="rounded-lg border border-ink-700 bg-ink-900/50 p-3">
            <Toggle
              checked={enabled}
              onChange={setEnabled}
              label="Block users below the minimum version"
              description="Enforced everywhere the app is used, immediately"
            />
          </div>

          <div className="flex items-center justify-between rounded-lg border border-ink-700 bg-ink-900/50 px-3 py-2.5">
            <div>
              <p className="text-xs text-ink-400">Minimum required version</p>
              <p className="text-sm font-semibold text-white">{minRequiredVersion || 'not set'}</p>
            </div>
            <button
              onClick={onOpenVersion}
              className="text-xs font-medium text-indigo-400 transition-colors hover:text-indigo-300"
            >
              Edit in App Version →
            </button>
          </div>

          {enabled && !minRequiredVersion && (
            <Banner tone="warning">
              No minimum version is set on the App Version card — with nothing to compare against, this won't block
              anyone yet.
            </Banner>
          )}
        </div>

        <div>
          <p className={labelClass}>Live preview</p>
          <PhonePreview>
            <span className="text-3xl">⬆️</span>
            <p className="text-sm font-bold text-white">Update Required</p>
            <p className="text-xs leading-relaxed text-ink-400">
              A new version of the app is required to continue. Please update to version{' '}
              {minRequiredVersion || '—'} or later.
            </p>
            <span
              className={`mt-1 rounded-lg px-3 py-1.5 text-[11px] font-medium ${
                config.playStoreUrl
                  ? 'bg-gradient-to-r from-indigo-500 to-violet-600 text-white'
                  : 'bg-ink-800 text-ink-500'
              }`}
            >
              Update Now
            </span>
          </PhonePreview>
        </div>
      </div>
      <ModalFooter onCancel={onClose} onSave={handleSave} saving={saving} dirty={dirty} />
    </Modal>
  )
}

// ============================================
// Privacy Policy / Terms (shared — plain text, en+bn, versioned)
// ============================================

function PolicyModal({ config, type, title, icon, onClose, onSaved }) {
  const [textEn, setTextEn] = useState(config[`${type}En`] || '')
  const [textBn, setTextBn] = useState(config[`${type}Bn`] || '')
  const [lang, setLang] = useState('en')
  const [previewing, setPreviewing] = useState(false)
  const [history, setHistory] = useState([])
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    fetchPolicyHistory(type).then(setHistory)
  }, [type])

  const dirty = textEn !== (config[`${type}En`] || '') || textBn !== (config[`${type}Bn`] || '')
  const activeText = lang === 'en' ? textEn : textBn
  const setActiveText = lang === 'en' ? setTextEn : setTextBn

  const handleSave = async () => {
    setSaving(true)
    try {
      await publishPolicy(type, { textEn, textBn })
      onSaved()
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal open title={`${icon} ${title}`} onClose={onClose} wide>
      <p className="mb-3 text-xs text-ink-500">
        Leaving both languages blank keeps the app's built-in {title.toLowerCase()} text. Publishing here overrides
        it live — no app release needed.
      </p>

      <div className="flex items-center justify-between">
        <div className="flex gap-1 rounded-lg border border-ink-700 bg-ink-900/50 p-1">
          {[
            { key: 'en', label: 'English', count: textEn.length },
            { key: 'bn', label: 'বাংলা', count: textBn.length },
          ].map((t) => (
            <button
              key={t.key}
              onClick={() => setLang(t.key)}
              className={`rounded-md px-3 py-1.5 text-xs font-medium transition-colors ${
                lang === t.key ? 'bg-indigo-500/20 text-white' : 'text-ink-400 hover:text-white'
              }`}
            >
              {t.label} <span className="text-ink-500">· {t.count}</span>
            </button>
          ))}
        </div>
        <button
          onClick={() => setPreviewing((p) => !p)}
          className="rounded-lg border border-ink-700 px-3 py-1.5 text-xs font-medium text-ink-300 transition-colors hover:border-indigo-500 hover:text-white"
        >
          {previewing ? '✎ Edit' : '👁 Preview'}
        </button>
      </div>

      <div className="mt-2">
        {previewing ? (
          <div className="max-h-72 min-h-[220px] overflow-y-auto rounded-lg border border-ink-700 bg-ink-900/50 p-4">
            {activeText.trim() ? (
              <p className="whitespace-pre-wrap text-sm leading-relaxed text-ink-200">{activeText}</p>
            ) : (
              <p className="text-sm italic text-ink-500">
                Nothing published for this language yet — the app's built-in text will show instead.
              </p>
            )}
          </div>
        ) : (
          <textarea
            value={activeText}
            onChange={(e) => setActiveText(e.target.value)}
            rows={11}
            placeholder={lang === 'en' ? 'Privacy policy text in English…' : 'বাংলায় লিখুন…'}
            className={`${inputClass} font-mono text-xs`}
          />
        )}
      </div>

      <HistoryTimeline
        items={history}
        renderLabel={(h) => `v${h.version}`}
        renderMeta={(h) => `${fmt(h.publishedAt)} · ${h.publishedBy || 'unknown'}`}
      />
      <ModalFooter onCancel={onClose} onSave={handleSave} saving={saving} dirty={dirty} />
    </Modal>
  )
}

// ============================================
// About App
// ============================================

function AboutAppModal({ config, onClose, onSaved }) {
  const [text, setText] = useState(config.aboutApp || '')
  const [saving, setSaving] = useState(false)
  const dirty = text !== (config.aboutApp || '')

  const handleSave = async () => {
    setSaving(true)
    try {
      await updateAppConfig({ aboutApp: text }, 'update_about')
      onSaved()
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal open title="ℹ️ About App" onClose={onClose} wide>
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-[1fr_200px]">
        <div>
          <label className={labelClass}>Shown on the app's "About" screen</label>
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            rows={8}
            placeholder="Smart Due helps small shop owners track customer dues, payments and reminders — all in one simple app."
            className={inputClass}
          />
          <p className="mt-1.5 text-xs text-ink-500">
            {text.length} characters · {text.trim() ? text.trim().split(/\s+/).length : 0} words
          </p>
        </div>
        <div>
          <p className={labelClass}>Live preview</p>
          <PhonePreview>
            <div className="w-full rounded-xl bg-gradient-to-br from-indigo-500 to-violet-600 p-3">
              <p className="text-sm font-extrabold text-white">Smart Due</p>
              <p className="text-[10px] text-white/80">Version 1.0.0</p>
            </div>
            <p className="text-xs leading-relaxed text-ink-300">
              {text.trim() || <span className="italic text-ink-500">Nothing set yet</span>}
            </p>
          </PhonePreview>
        </div>
      </div>
      <ModalFooter onCancel={onClose} onSave={handleSave} saving={saving} dirty={dirty} />
    </Modal>
  )
}

// ============================================
// Contact
// ============================================

const CONTACT_FIELDS = [
  { key: 'supportEmail', icon: '📧', label: 'Support email', placeholder: 'support@example.com' },
  { key: 'supportPhone', icon: '☎️', label: 'Support phone', placeholder: '+8801XXXXXXXXX' },
  { key: 'whatsapp', icon: '💬', label: 'WhatsApp number', placeholder: '+8801XXXXXXXXX' },
  { key: 'facebook', icon: '📘', label: 'Facebook page URL', placeholder: 'https://facebook.com/...' },
  { key: 'website', icon: '🌐', label: 'Website URL', placeholder: 'https://...' },
]

function ContactModal({ config, onClose, onSaved }) {
  const [values, setValues] = useState(
    Object.fromEntries(CONTACT_FIELDS.map((f) => [f.key, config[f.key] || ''])),
  )
  const [saving, setSaving] = useState(false)
  const dirty = CONTACT_FIELDS.some((f) => values[f.key] !== (config[f.key] || ''))
  const setCount = CONTACT_FIELDS.filter((f) => values[f.key].trim()).length

  const handleSave = async () => {
    setSaving(true)
    try {
      await updateAppConfig(values, 'update_contact')
      onSaved()
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal open title="📞 Contact" onClose={onClose}>
      <div className="space-y-3">
        {CONTACT_FIELDS.map((f) => (
          <div key={f.key}>
            <label className={labelClass}>
              <span>{f.icon}</span> {f.label}
            </label>
            <input
              value={values[f.key]}
              onChange={(e) => setValues((v) => ({ ...v, [f.key]: e.target.value }))}
              placeholder={f.placeholder}
              className={inputClass}
            />
          </div>
        ))}
      </div>
      <p className="mt-3 text-xs text-ink-500">
        {setCount} of {CONTACT_FIELDS.length} channels set — shown on the app's Contact screen
      </p>
      <ModalFooter onCancel={onClose} onSave={handleSave} saving={saving} dirty={dirty} />
    </Modal>
  )
}

// ============================================
// Page
// ============================================

export default function AppConfigPage() {
  const [config, setConfig] = useState(null)
  const [loadError, setLoadError] = useState('')
  const [openModal, setOpenModal] = useState(null)

  useEffect(() => {
    load()
  }, [])

  async function load() {
    setLoadError('')
    try {
      setConfig(await fetchAppConfig())
    } catch (e) {
      setLoadError(e.message || 'Could not load app config.')
    }
  }

  async function handleSaved() {
    setOpenModal(null)
    await load()
  }

  if (loadError) {
    return (
      <div className="flex h-64 flex-col items-center justify-center gap-3 p-6 text-center">
        <p className="text-sm text-red-400">{loadError}</p>
        <button
          onClick={load}
          className="rounded-lg border border-ink-700 px-3 py-1.5 text-sm font-medium text-ink-300 transition-colors hover:border-indigo-500 hover:text-white"
        >
          Retry
        </button>
      </div>
    )
  }

  if (!config) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-7 w-7 animate-spin rounded-full border-2 border-ink-700 border-t-indigo-500" />
      </div>
    )
  }

  const maintenanceUntilText = config.maintenanceUntil?.toDate
    ? `ETA ${config.maintenanceUntil.toDate().toLocaleString()}`
    : null

  return (
    <div className="max-w-4xl p-6 md:p-8">
      <h1 className="text-xl font-semibold text-white">App Config</h1>
      <p className="mt-1 text-sm text-ink-400">
        One shared config, each card saves independently. Changes to Maintenance Mode and Force Update take effect
        immediately in the app.
      </p>

      <div className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <ConfigCard
          icon="🏷️"
          title="App Version"
          summary={`current ${config.currentVersion || '—'} · min ${config.minRequiredVersion || '—'}`}
          onClick={() => setOpenModal('version')}
        />
        <ConfigCard
          icon="🚧"
          title="Maintenance Mode"
          summary={maintenanceUntilText || (config.maintenanceEnabled ? 'Blocking the app' : 'App is live')}
          badge={<Badge on={config.maintenanceEnabled} />}
          onClick={() => setOpenModal('maintenance')}
        />
        <ConfigCard
          icon="⬆️"
          title="Force Update"
          summary={config.forceUpdateEnabled ? `Blocks below ${config.minRequiredVersion || '—'}` : 'Not enforced'}
          badge={<Badge on={config.forceUpdateEnabled} />}
          onClick={() => setOpenModal('forceUpdate')}
        />
        <ConfigCard
          icon="🔒"
          title="Privacy Policy"
          summary={config.privacyVersion ? `Published v${config.privacyVersion}` : 'Using built-in default'}
          onClick={() => setOpenModal('privacy')}
        />
        <ConfigCard
          icon="📄"
          title="Terms & Conditions"
          summary={config.termsVersion ? `Published v${config.termsVersion}` : 'Using built-in default'}
          onClick={() => setOpenModal('terms')}
        />
        <ConfigCard
          icon="ℹ️"
          title="About App"
          summary={config.aboutApp ? `${config.aboutApp.length} characters set` : 'Not set'}
          onClick={() => setOpenModal('about')}
        />
        <ConfigCard
          icon="📞"
          title="Contact"
          summary={config.supportEmail || config.supportPhone || 'Not set'}
          onClick={() => setOpenModal('contact')}
        />
        <Link
          to="/app-config/faq"
          className="flex flex-col items-start gap-2 rounded-2xl border border-dashed border-ink-700 bg-ink-900/40 p-5 text-left transition-colors hover:border-indigo-500"
        >
          <span className="text-2xl">❓</span>
          <p className="font-semibold text-white">FAQ Management</p>
          <p className="text-sm text-ink-400">Manage the in-app FAQ list →</p>
        </Link>
      </div>

      {openModal === 'version' && (
        <AppVersionModal config={config} onClose={() => setOpenModal(null)} onSaved={handleSaved} />
      )}
      {openModal === 'maintenance' && (
        <MaintenanceModal config={config} onClose={() => setOpenModal(null)} onSaved={handleSaved} />
      )}
      {openModal === 'forceUpdate' && (
        <ForceUpdateModal
          config={config}
          onClose={() => setOpenModal(null)}
          onSaved={handleSaved}
          onOpenVersion={() => setOpenModal('version')}
        />
      )}
      {openModal === 'privacy' && (
        <PolicyModal
          config={config}
          type="privacy"
          title="Privacy Policy"
          icon="🔒"
          onClose={() => setOpenModal(null)}
          onSaved={handleSaved}
        />
      )}
      {openModal === 'terms' && (
        <PolicyModal
          config={config}
          type="terms"
          title="Terms & Conditions"
          icon="📄"
          onClose={() => setOpenModal(null)}
          onSaved={handleSaved}
        />
      )}
      {openModal === 'about' && (
        <AboutAppModal config={config} onClose={() => setOpenModal(null)} onSaved={handleSaved} />
      )}
      {openModal === 'contact' && (
        <ContactModal config={config} onClose={() => setOpenModal(null)} onSaved={handleSaved} />
      )}
    </div>
  )
}
