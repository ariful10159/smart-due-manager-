# Smart Due Manager — Project Overview

A Flutter-based digital ledger ("digital khata") app for small business owners and shopkeepers to track customer credit/dues, record payments, send due-date reminders, and generate reports/receipts — with a Bangla-first UI and offline-first data backed by Firebase.

## Summary

Small shopkeepers traditionally track customer credit ("বাকি"/due) in paper notebooks, which leads to lost records, calculation mistakes, and missed collections. **Smart Due Manager** digitizes this workflow: every customer gets a digital ledger of dues and payments, due dates trigger local reminder notifications, and the shopkeeper can generate PDF receipts/reports and back up data to the cloud — all while working fully offline for day-to-day use.

## Platforms & Tech Stack

- **Framework:** Flutter (Dart SDK ^3.11.5) — single codebase targeting **Android, Windows, and Linux**
- **Backend:** Firebase — Authentication, Cloud Firestore, Storage, Crashlytics
- **Local persistence:** `shared_preferences` for settings/PIN, offline-first data flow
- **Notifications:** `flutter_local_notifications` + `timezone` for scheduled due-date reminders
- **Security:** `local_auth` (biometric/fingerprint unlock), `crypto` (PIN hashing)
- **Documents/Export:** `pdf` + `printing` (PDF receipts/reports), `csv` (import/export), `share_plus` (sharing)
- **Rich text:** `flutter_quill` (used in the notebook/notes feature)
- **Charts:** `fl_chart` for dashboard/report analytics
- **Localization:** `flutter_localizations` + custom `l10n` — Bangla (bn) and English (en), Noto Serif Bengali font

## Architecture

```
lib/
├── models/       # Data models + Firestore repositories (Customer, Payment, Notebook, Reminder, AppSettings, LegalContent)
├── providers/     # App-wide state (AppSettingsController)
├── services/      # Business logic (Auth, Backup/CSV, Notifications, PIN/lockout, PDF receipts, Settings)
├── screens/       # UI screens (auth, customers, notebook, reminders, reports, settings)
├── widgets/       # Reusable UI (drawer, bottom nav, app-lock gate, payment tile, legal doc viewer)
├── theme/         # App color/theme definitions
├── utils/         # Constants, helpers, HTML escaping, Bengali PDF text helpers
└── l10n/          # Bangla/English localization
```

## Key Features

### 1. Authentication & Onboarding
- Phone-number based login/registration (no email required — matches how local shopkeepers identify themselves), backed by Firebase Auth
- Splash screen with session check → auto-routes to login or home
- App-lock gate shown right after launch if enabled

### 2. Customer & Ledger Management
- Add, edit, search, and archive/hide customers
- Each customer has: name, phone, address, photo, notes, custom fields, running **total due** balance
- Per-customer detail screen showing full payment/due history
- **Global search** across all customers and ledger entries
- Automatically-calculated running due balance as payments/dues are logged

### 3. Digital Notebook (Payments & Dues)
- Log a **due added** or **payment received** entry per customer, with amount, discount, payment method (bKash, Nagad, Hand Cash, Bank), note, and optional receipt image
- Full payment history timeline per customer
- Separate rich-text **Notebook** feature (with `flutter_quill`) for freeform notes/pages, organized into notebooks with reorderable pages
- Notebook list + notebook editor screens for managing multiple notebooks

### 4. Reminders & Notifications
- Schedule due-date reminders per customer, including **recurring reminders** (weekly / biweekly / monthly)
- Local scheduled notifications (works offline, no push server needed) via `flutter_local_notifications`
- Tapping a reminder opens the device's SMS app **pre-filled** with a customizable message — a zero-cost alternative to paid SMS gateways
- Full **reminder history log** so past reminders sent to each customer are tracked
- Customizable SMS templates: a due-reminder template and a separate "full payment thank-you" template, both with placeholders (`{name}`, `{amount}`, `{due_date}`, `{business_name}`, `{phone}`)

### 5. Reports, Receipts & Data Export
- Generate **PDF receipts** for individual payments (with Bengali font support)
- Generate **PDF customer reports/statements** and overall business reports
- Interactive **charts** (via `fl_chart`) on the dashboard/report screen — daily/weekly collections, outstanding dues, etc.
- **CSV export/import** of customer records with Bangla column headers
- Share generated PDFs/CSVs directly via the device share sheet

### 6. Security & Privacy
- **PIN-based app lock**, with optional **fingerprint/biometric unlock** (`local_auth`)
- PIN is hashed (never stored in plaintext) via `crypto`
- **Escalating lockout** after repeated failed PIN attempts (increasing delay, persisted across app restarts) to resist brute-force guessing
- Per-user data isolation via `ownerId` on every Firestore record

### 7. Settings & Customization
- Business profile (business name, owner name, address, logo)
- Theme customization: dark/light mode, accent color picker (16 preset colors)
- Currency symbol selection (৳, $, €, ₹, £)
- Font-size scaling for accessibility
- Language switch: Bangla / English
- SMS template editor (due-reminder and thank-you templates)
- App-lock settings (enable/disable PIN, biometric toggle)
- Data backup & restore settings (CSV export/import, Firebase cloud backup)

### 8. Cloud Backup & Sync
- Optional Firebase Firestore backend so data is recoverable if the device is lost, stolen, or replaced
- Firebase Storage for receipt/business-logo images
- Firebase Crashlytics for crash reporting
- Offline-first: core operations (add customer, log due/payment, view ledger) work with no internet connection

### 9. Legal & Support
- In-app Privacy Policy and Terms of Service screens
- Help & Support screen

## Data Model (Firestore Collections)

| Model | Purpose |
|---|---|
| `Customer` | Customer profile, running due balance, reminder settings, custom fields |
| `Payment` | Individual due/payment transaction tied to a customer |
| `Reminder` | Scheduled/sent reminder record (status: active/expired/completed) |
| `Notebook` / `NotebookPage` | Freeform rich-text notebooks and their pages |
| `AppSettings` | Per-user app configuration (theme, currency, templates, PIN hash, language) |
| `LegalContent` | Privacy policy / terms content |

## Notable Design Choices

- **Zero-cost reminders:** instead of paid SMS gateways, the app schedules a local notification that opens the phone's native SMS app pre-filled — the shopkeeper taps send, at no recurring cost.
- **Bangla-first UX:** phone-number login, Bangla CSV headers, Bangla PDF fonts (Noto Serif Bengali), and full Bangla/English localization.
- **One codebase, three platforms:** Android, Windows, and Linux builds from the same Flutter code.
- **Offline-first:** daily ledger operations don't require internet; Firebase sync is a safety net, not a dependency.

---
*Note: A more formal academic-style summary of this project (abstract, objectives, novelty, expected impact) is available in [project_summary.typ](project_summary.typ).*
