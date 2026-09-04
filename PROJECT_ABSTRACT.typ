#let accent = rgb("#1f6f52")
#let accent-dark = rgb("#155c42")
#let light-bg = rgb("#eaf5ef")
#let light-border = rgb("#cfe8db")

#set page(paper: "a4", margin: 2.2cm, footer: align(center)[
  #text(size: 9pt, fill: gray)[Smart Due Manager — Project Abstract]
])
#set text(size: 10.6pt)
#set par(justify: true, leading: 0.62em)

#show heading.where(level: 1): it => block(width: 100%, above: 16pt, below: 8pt)[
  #text(fill: accent-dark, weight: "bold", size: 13pt)[#it.body]
  #v(2pt)
  #line(length: 100%, stroke: 0.8pt + accent)
]

// ============================================================
// Cover Page
// To use the real university logo, save it as an image (e.g.
// "assets/pstu_logo.png") next to this file and replace the
// placeholder #box(...) below with:
//   #image("assets/pstu_logo.png", width: 90pt)
// ============================================================
#align(center)[
  #v(30pt)
  #box(width: 95pt, height: 95pt, radius: 50%, stroke: 1.2pt + accent, fill: light-bg)[
    #align(center + horizon)[
      #text(fill: accent-dark, size: 8pt, style: "italic")[University\ Logo]
    ]
  ]
  #v(16pt)
  #text(size: 15.5pt, weight: "bold")[Patuakhali Science and Technology University]
  #v(4pt)
  #text(size: 12pt, fill: rgb("#444444"))[Faculty of Computer Science and Engineering]

  #v(40pt)
  #line(length: 55%, stroke: 0.8pt + accent)
  #v(22pt)
  #text(size: 10.5pt, fill: rgb("#666666"))[PROJECT TITLE]
  #v(6pt)
  #text(size: 24pt, weight: "bold", fill: accent-dark)[Smart Due Manager]
  #v(4pt)
  #text(size: 12pt, style: "italic", fill: rgb("#444444"))[A Digital Ledger and Customer Due-Management Platform for Small Businesses]
  #v(22pt)
  #line(length: 55%, stroke: 0.8pt + accent)

  #v(40pt)
  #text(size: 11pt, weight: "bold", fill: accent-dark)[Submitted By]
  #v(12pt)

  #table(
    columns: (auto, auto, auto, auto, auto),
    stroke: 0.6pt + light-border,
    inset: (x: 12pt, y: 8pt),
    fill: (x, y) => if y == 0 { accent-dark } else if calc.rem(y, 2) == 0 { light-bg } else { white },
    align: horizon,
    [#text(fill: white, weight: "bold", size: 9pt)[Name]],
    [#text(fill: white, weight: "bold", size: 9pt)[ID]],
    [#text(fill: white, weight: "bold", size: 9pt)[Reg. No.]],
    [#text(fill: white, weight: "bold", size: 9pt)[Semester]],
    [#text(fill: white, weight: "bold", size: 9pt)[Session]],

    [Ariful Islam Masum], [2102032], [10159], [7th], [2021 – 2022],
    [Imamaul Kabir Anan], [2102065], [10192], [7th], [2021 – 2022],
  )

  #v(1fr)
  #text(size: 9.5pt, fill: rgb("#555555"))[Prepared for National-Level Competition Submission]
  #v(20pt)
]

#pagebreak()

// ---- Header ----
#grid(
  columns: (44pt, 1fr),
  column-gutter: 12pt,
  align: horizon,
  [
    #box(width: 40pt, height: 40pt, radius: 50%, fill: accent)[
      #align(center + horizon)[#text(fill: white, weight: "bold", size: 18pt)[S]]
    ]
  ],
  [
    #text(size: 20pt, weight: "bold")[Smart Due Manager]
    #v(2pt)
    #text(size: 11pt, style: "italic", fill: rgb("#444444"))[A Digital Ledger and Customer Due-Management Platform for Small Businesses]
  ]
)

#v(10pt)
#text(size: 9.5pt)[
  *Category:* Computer Science / Software Engineering — Mobile & Cloud Application Development #h(4pt) | #h(4pt) *Platforms:* Android · Windows · Linux (Flutter) + Web-based Admin Console (React) #h(4pt) | #h(4pt) *Backend:* Firebase (Auth, Firestore, Storage, Cloud Functions, Crashlytics, Cloud Messaging, App Check)
]

= Abstract
Across Bangladesh and South Asia, small shopkeepers still manage customer credit, locally known as “baki” (due), using handwritten notebooks (“khata”). This system is vulnerable to lost records, calculation errors, overdue payments, and undocumented disputes.

Smart Due Manager is a full-stack, cross-platform solution that digitizes this workflow. Built with Flutter, it runs on Android, Windows, and Linux from a single codebase, offering per-customer digital ledgers, automatic balance calculation, due-date reminders, PDF reports/receipts, and CSV import/export through a Bangla-first interface. Its offline-first architecture enables daily operations without internet, while optional Firebase cloud sync provides data recovery.

The project also includes a React + Firebase Admin Console and serverless Cloud Functions for admin management, notifications, FAQ management, audit logging, remote configuration, and user support.

Smart Due Manager is not merely a classroom prototype. It is already deployed and actively used by 4 independent small businesses, with real transaction data validating its practical use in the field.

= Innovation / Novelty
Most "digital khata" apps simply move a paper ledger onto a screen. Smart Due Manager rethinks the underlying engineering for the real constraints of a small South Asian shopkeeper:

- *Zero-cost reminders.* Instead of a paid bulk-SMS gateway or in-app credits, a scheduled local notification opens the device's native SMS app pre-filled with the reminder text — the shopkeeper taps Send once, at zero recurring cost, fully within platform SMS policy.
- *Escalating brute-force lockout.* Repeated failed PIN attempts trigger an increasing lockout delay (seconds to minutes), persisted across app restarts, so financial data is genuinely protected — not just gated by a static PIN screen.
- *Bangla-first, not Bangla-translated.* Phone-number login (matching how local shopkeepers actually identify themselves), Bangla CSV headers, and a dedicated Bengali font pipeline for PDF exports — localization is a design constraint, not an afterthought.
- *Offline-first with optional cloud sync.* Every core operation — adding a customer, logging a due, recording a payment — works with zero connectivity; Firebase is a safety net, not a dependency.
- *One codebase, three platforms.* A single Flutter codebase ships native builds for Android, Windows, and Linux, so the same business can be managed from a phone or a desktop.
- *A real operations backend, not just an app.* A production-style admin console handles role-based admin access, remote force-update/maintenance control, push announcements, an in-app FAQ system, user problem-reports, and Firestore-backed audit logs — governance infrastructure rarely present in student or hackathon-scale projects.
- *Defense-in-depth security.* Firebase App Check on all sensitive Cloud Functions, hashed PIN storage (never plaintext), per-user data isolation via `ownerId` on every record, and fine-grained Firestore security rules (900+ lines) that enforce access control at the database layer, not just the UI layer.

= Key Features

#set text(size: 9pt)
#table(
  columns: (1.15fr, 2.6fr),
  stroke: 0.6pt + light-border,
  inset: 7pt,
  fill: (x, y) => if y == 0 { accent-dark } else if calc.rem(y, 2) == 0 { light-bg } else { white },
  align: (x, y) => if y == 0 { horizon } else { top + left },
  [#text(fill: white, weight: "bold", size: 9.5pt)[Category]], [#text(fill: white, weight: "bold", size: 9.5pt)[Description]],

  [*Authentication & Onboarding*],
  [Phone-number and OTP-based login/registration, a forgot-password and change-password flow, a session-aware splash screen, and a mandatory Privacy Policy / Terms of Service acceptance gate.],

  [*Customer & Ledger Management*],
  [Adding, searching, and archiving customers; a per-customer due and payment ledger; automatically calculated running due balance; and global search across all customers and entries.],

  [*Digital Notebook (Rich-Text Notes)*],
  [A freeform rich-text notebook module (Quill editor), independent of the customer ledger, supporting multiple notebooks with reorderable pages for general business notes.],

  [*Reminders & Notifications*],
  [Scheduled local due-date reminders, including recurring schedules; one-tap, pre-filled SMS reminders; customizable SMS templates with placeholders; a full reminder history log; in-app notifications; and push notifications via Firebase Cloud Messaging.],

  [*Reports, Receipts & Export*],
  [Bengali-font PDF receipts and statements; interactive charts for dashboard analytics; CSV import/export with Bangla headers; and native share-sheet integration.],

  [*Security & Privacy*],
  [PIN and fingerprint/biometric app lock; an escalating lockout policy after failed PIN attempts; hashed credential storage; per-user data isolation; and App Check-enforced Cloud Functions.],

  [*Personalization & Settings*],
  [Business profile configuration (name, owner, address, logo); dark/light mode with a sixteen-color accent theme; currency symbol selection; font-size scaling; and a Bangla/English language switch.],

  [*Support, Legal & Communication*],
  [In-app FAQ, Help & Support, Contact, and About sections; an admin-broadcast announcement banner; an in-app "Report a Problem" flow; Privacy Policy and Terms of Service screens; and self-service account deletion.],

  [*Cloud & Reliability*],
  [Offline-first core operation; optional Firebase-based backup and restore; Crashlytics crash reporting; and remote force-update and maintenance-mode handling.],

  [*Admin & Governance (Web Console)*],
  [Dashboard analytics and global search; role-based admin management with audit logging; push-notification broadcast, announcements, and FAQ management; a problem-report inbox; per-user account controls; and remote app configuration.],
)
#set text(size: 10.6pt)

= UI Preview

// To place a real screenshot, call phone-mockup with a path, e.g.:
//   phone-mockup("Customer Ledger", path: "photo1.jpg")
// Use clean, release-mode screenshots only (no debug banner, no keyboard,
// no real customer PII) — replace names/numbers with sample data first.
#let phone-mockup(caption, path: none) = block(
  width: 100%,
  above: 0pt, below: 4pt,
)[
  #box(
    width: 100%,
    height: 230pt,
    radius: 10pt,
    stroke: 1pt + light-border,
    fill: light-bg,
    clip: true,
  )[
    #if path != none [
      #image(path, width: 100%, height: 100%, fit: "contain")
    ] else [
      #align(center + horizon)[
        #text(fill: rgb("#8a9a92"), size: 8.5pt, style: "italic")[Screenshot placeholder]
        #v(2pt)
        #text(fill: rgb("#8a9a92"), size: 8.5pt, style: "italic")[#caption]
      ]
    ]
  ]
  #v(4pt)
  #align(center)[#text(size: 8.5pt, fill: accent-dark, weight: "bold")[#caption]]
]

#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 10pt,
  row-gutter: 14pt,
  phone-mockup("Customer Ledger", path: "photo1.jpg"),
  phone-mockup("Add Due / Payment", path: "photo2.jpg"),
  phone-mockup("Reports & Analytics", path: "photo3.jpg"),
  phone-mockup("Feature 4", path: "photo4.jpg"),
  phone-mockup("Feature 5", path: "photo5.jpg"),
  phone-mockup("Feature 6", path: "photo7.jpg"),
  
)

= Real-World Deployment & Traction
Unlike a purely academic prototype, Smart Due Manager is *already installed and running in 4 independent small businesses*, replacing their paper khata with digital records. System-generated monthly collection reports from one of these shops confirm genuine, growing day-to-day usage:

#align(center)[
  #table(
    columns: (1.3fr, 1.3fr, 1.6fr),
    stroke: 0.6pt + light-border,
    inset: 8pt,
    fill: (x, y) => if y == 0 { accent } else if calc.rem(y, 2) == 0 { light-bg } else { white },
    [#text(fill: white, weight: "bold")[Month]], [#text(fill: white, weight: "bold")[Customers Tracked]], [#text(fill: white, weight: "bold")[Total Collection]],
    [July 2026], [7], [BDT 27,802.00],
    [August 2026], [17], [BDT 128,581.00],
  )
]

Between the two months, the shop grew from 7 to 17 tracked customers and recorded collections rose from BDT 27,802 to BDT 128,581 — a real shop owner actively onboarding customers and relying on the app for day-to-day due collection, not a one-time trial. This is direct, system-generated evidence from one of the four live deployments.

#text(style: "italic", size: 9pt, fill: rgb("#555555"))[Individual customer names, phone numbers, and per-customer due amounts are owned by the respective shop's customers and are withheld here for privacy; only aggregate, anonymized figures are reported.]

= Conclusion
Smart Due Manager demonstrates that a genuinely useful digitization solution for an underserved, informal-economy use case does not require compromising on engineering rigor. It combines a Bangla-first, offline-capable mobile experience with a properly governed cloud backend and administrative tooling — delivering both immediate value to individual shopkeepers and a maintainable, extensible platform for long-term operation.

#v(6pt)
#align(center)[
  #text(style: "italic", size: 9pt, fill: gray)[Prepared as a project abstract for national-level competition submission.]
]
