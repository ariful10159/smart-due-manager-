# Smart Due Manager
### A Digital Ledger and Customer Due-Management Platform for Small Businesses



## Abstract

Across Bangladesh and much of South Asia, small shopkeepers and micro-business owners still track customer credit — locally known as **"বাকি" (baki/due)** — in handwritten paper notebooks (khata). This informal system is fragile: pages get lost or torn, arithmetic errors go unnoticed, there is no reminder mechanism for overdue payments, and disputes over "how much is actually owed" are common and often undocumented.

**Smart Due Manager** is a full-stack, cross-platform software system that digitizes this entire workflow end to end. Built with Flutter, it runs natively on **Android, Windows, and Linux** from a single codebase, giving a shopkeeper a per-customer digital ledger, automatic running-balance calculation, scheduled due-date reminders, PDF receipt/report generation, and CSV import/export — all through a **Bangla-first interface** (phone-number login, Bangla fonts, Bangla export headers) designed around how local business owners actually work. The application is **offline-first**: every day-to-day operation works with zero internet connection, while an optional Firebase-backed cloud sync keeps data safely recoverable if a device is lost, damaged, or replaced.

Beyond the end-user app, the project includes a **secondary web-based Admin Console** (React + Firebase) and a set of **serverless Cloud Functions** that together form a genuine operations backend — role-based admin management, push notifications, a live FAQ knowledge base, audit logging, remote app configuration (force-update and maintenance mode), and user-support tooling. This turns Smart Due Manager from a single mobile app into a maintainable, governable software product — the kind of architecture typically found in production SaaS systems rather than student prototypes.

By replacing paper ledgers with a secure, auditable, zero-subscription-cost digital system, Smart Due Manager directly targets financial-record digitization for the informal micro-retail sector, a segment that mainstream fintech and enterprise software largely ignores. The project is not a classroom prototype: it is **already installed and running in 4 independent small businesses**, with real transaction data from live usage validating the product in the field (see *Real-World Deployment & Traction* below).

---

## Innovation / Novelty

Most "digital khata" apps simply move a paper ledger onto a screen. Smart Due Manager rethinks the underlying engineering for the real constraints of a small South Asian shopkeeper:

- **Zero-cost reminders.** Instead of a paid bulk-SMS gateway or in-app credits, a scheduled local notification opens the device's native SMS app pre-filled with the reminder text — the shopkeeper taps *Send* once, at zero recurring cost, fully within platform SMS policy.
- **Escalating brute-force lockout.** Repeated failed PIN attempts trigger an increasing lockout delay (seconds → minutes), persisted across app restarts, so financial data is genuinely protected — not just gated by a static PIN screen.
- **Bangla-first, not Bangla-translated.** Phone-number login (matching how local shopkeepers actually identify themselves), Bangla CSV headers, and a dedicated Bengali font pipeline for PDF exports — localization is a design constraint, not an afterthought.
- **Offline-first with optional cloud sync.** Every core operation — adding a customer, logging a due, recording a payment — works with zero connectivity; Firebase is a safety net, not a dependency.
- **One codebase, three platforms.** A single Flutter codebase ships native builds for Android, Windows, and Linux, so the same business can be managed from a phone or a desktop.
- **A real operations backend, not just an app.** A production-style admin console handles role-based admin access, remote force-update/maintenance control, push announcements, an in-app FAQ system, user problem-reports, and Firestore-backed audit logs — governance infrastructure rarely present in student or hackathon-scale projects.
- **Defense-in-depth security.** Firebase App Check on all sensitive Cloud Functions, hashed PIN storage (never plaintext), per-user data isolation via `ownerId` on every record, and fine-grained Firestore security rules (900+ lines) that enforce access control at the database layer, not just the UI layer.

## Key Features

| Category | Highlights |
|---|---|
| **Authentication & Onboarding** | Phone-number + OTP login/registration, forgot/change-password flow, session-aware splash screen, mandatory Privacy Policy/Terms acceptance gate |
| **Customer & Ledger Management** | Add/search/archive customers, per-customer due & payment ledger, auto-calculated running due balance, global cross-customer search |
| **Digital Notebook (Rich-Text Notes)** | Freeform rich-text notebooks (Quill editor) separate from the customer ledger, multiple notebooks with reorderable pages, for general business notes |
| **Reminders & Notifications** | Scheduled local due-date reminders (incl. recurring), one-tap pre-filled SMS, customizable SMS templates with placeholders, full reminder history log, in-app notification center, push notifications via FCM |
| **Reports, Receipts & Export** | Bengali-font PDF receipts & statements, interactive charts (fl_chart) for dashboards, CSV import/export with Bangla headers, native share sheet integration |
| **Security & Privacy** | PIN + fingerprint/biometric app lock, escalating lockout, hashed credentials, per-user data isolation, App Check-enforced Cloud Functions |
| **Personalization & Settings** | Business profile (name, owner, address, logo), dark/light mode + 16-color accent theme, currency symbol selection, font-size scaling, Bangla/English language switch |
| **Support, Legal & Communication** | In-app FAQ/Help & Support/Contact/About, admin announcement banner, in-app "Report a Problem" flow, Privacy Policy & Terms of Service screens, self-service account deletion |
| **Cloud & Reliability** | Offline-first core, optional Firebase backup/restore, Crashlytics crash reporting, remote force-update & maintenance mode |
| **Admin & Governance (Web Console)** | Dashboard analytics, global search, role-based admin management, push-notification broadcast, announcements, FAQ management, problem-report inbox, Firestore-backed audit log, per-user account controls (disable, reset PIN, delete data), remote app configuration |

## Real-World Deployment & Traction

Unlike a purely academic prototype, Smart Due Manager is **already installed and running in 4 independent small businesses**, replacing their paper khata with digital records. System-generated monthly collection reports from one of these shops confirm genuine, growing day-to-day usage:

| Month | Customers Tracked | Total Collection Recorded |
|---|---|---|
| July 2026 | 7 | ৳27,802 |
| August 2026 | 17 | ৳128,581 |

Between the two months, the shop grew from 7 to 17 tracked customers and recorded collections rose from ৳27,802 to ৳128,581 — a real shop owner actively onboarding customers and relying on the app for day-to-day due collection, not a one-time trial. This is direct, system-generated evidence from one of the four live deployments.

*(Individual customer names, phone numbers, and per-customer due amounts are owned by the respective shop's customers and are withheld here for privacy; only aggregate, anonymized figures are reported.)*

## Conclusion

Smart Due Manager demonstrates that a genuinely useful digitization solution for an underserved, informal-economy use case does not require compromising on engineering rigor. It combines a Bangla-first, offline-capable mobile experience with a properly governed cloud backend and administrative tooling — delivering both immediate value to individual shopkeepers and a maintainable, extensible platform for long-term operation.

---
*Prepared as a project abstract for national-level competition submission.*
