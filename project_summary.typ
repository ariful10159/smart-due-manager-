#let accent = rgb("#1f6f52")
#let accent-dark = rgb("#155c42")
#let light-bg = rgb("#eaf5ef")
#let light-border = rgb("#cfe8db")

#set page(paper: "a4", margin: 2.2cm, footer: align(center)[
  #text(size: 9pt, fill: gray)[Smart Due Manager — Project Summary]
])
#set text(size: 10.6pt)
#set par(justify: true, leading: 0.62em)

#show heading.where(level: 1): it => block(width: 100%, above: 16pt, below: 8pt)[
  #text(fill: accent-dark, weight: "bold", size: 13pt)[#it.body]
  #v(2pt)
  #line(length: 100%, stroke: 0.8pt + accent)
]

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
    #text(size: 11pt, style: "italic", fill: rgb("#444444"))[A Digital Ledger and Customer Due Management App for Small Businesses]
  ]
)

#v(10pt)
#text(size: 9.5pt)[
  *Scientific Field:* Computer Science / Software Engineering (Mobile Application Development) #h(4pt) | #h(4pt) *Platform:* Android · Windows · Linux #h(4pt) | #h(4pt) *Backend:* Firebase (Auth, Firestore, Storage, Crashlytics)
]

= Project Abstract
Small business owners and shopkeepers in Bangladesh still rely heavily on paper-based ledgers ("khata") to track customer credit and due payments, leading to record loss, calculation errors, and missed collection dates. Smart Due Manager is a cross-platform Flutter application (Android, Windows, Linux) that digitizes this process end to end. It lets shopkeepers register customers, maintain a per-customer payment notebook, log dues and repayments, schedule automatic reminder notifications for due dates, generate PDF receipts and itemized reports, and export/import records via CSV — all through a Bangla-first interface designed specifically for the local market. The app combines an offline-first core with optional Firebase-based cloud backup, so daily operations work without internet while data remains safely recoverable across devices.

= Objectives
+ Replace manual paper-based ledgers with a secure, structured digital record system.
+ Give every customer a dedicated digital notebook that tracks running dues and payment history.
+ Automate due-date tracking and send timely, low-cost payment reminders to reduce missed collections.
+ Provide instant, shareable PDF receipts and customer/business reports for professional record-keeping.
+ Protect sensitive financial data with PIN/fingerprint authentication and brute-force lockout protection.
+ Ensure data safety and portability through cloud backup, CSV export/import, and multi-platform support.
+ Support a Bangla-first experience, from phone-number login to Bangla report and export headers.

= Innovation / Novelty
While most digital ledger apps simply replicate the same paper-khata concept on a screen, Smart Due Manager rethinks the underlying engineering for the realities of a small Bangladeshi shopkeeper:

- *Zero-cost reminders.* Most competing apps charge for bulk SMS reminders through paid gateways or in-app credits. Smart Due Manager sidesteps this entirely — a scheduled local notification, when tapped, opens the device's own SMS app pre-filled with the reminder message. The shopkeeper sends it with one tap, at zero recurring cost, and fully within Play Store policy on app-initiated SMS.
- *Escalating brute-force lockout.* Security goes beyond a static PIN screen. Repeated failed attempts trigger an escalating lockout, from 30 seconds up to 5 minutes, persisted even if the app is closed and reopened, so financial data stays genuinely protected against guessing attacks.
- *Bangla-first design.* Phone-number login instead of email, since that is how local shopkeepers actually identify themselves, plus Bangla CSV headers and Bangla PDF fonts for exports and reports.
- *Offline-first with optional cloud sync.* Every core feature — adding customers, logging dues, recording payments — works with zero internet connection, while Firebase keeps data recoverable if the phone is lost, stolen, or replaced.
- *One codebase, three platforms.* A single Flutter codebase powers native builds for Android, Windows, and Linux, letting the same shopkeeper manage their business from a phone or a desktop.
- *Built-in analytics.* Interactive charts (fl_chart) turn raw ledger entries into at-a-glance insight on collections, outstanding dues, and customer activity, without needing a separate spreadsheet.

= Expected Impact
By digitizing due-payment tracking, Smart Due Manager can help small shopkeepers reduce accounting errors, recover more of their outstanding dues through automated reminders, and save time otherwise spent on manual bookkeeping. Transparent, timestamped digital records also reduce disputes between shopkeepers and customers over how much is owed. Because it is free of subscription fees, SMS credits, or gateway costs, the app is directly accessible to micro and small businesses that cannot afford premium ledger tools — supporting broader financial digitization and record-keeping practices among Bangladesh's informal retail sector.

= Key Features

#let feature-box(title, items) = block(
  width: 100%,
  fill: light-bg,
  stroke: 0.6pt + light-border,
  radius: 5pt,
  inset: 10pt,
  above: 0pt, below: 10pt,
)[
  #text(fill: accent-dark, weight: "bold", size: 10.5pt)[#title]
  #v(4pt)
  #for i in items [- #i]
]

#grid(
  columns: (1fr, 1fr),
  column-gutter: 14pt,
  [
    #feature-box("Customer & Ledger Management", (
      "Add, search, and archive customers",
      "Per-customer digital notebook of dues & payments",
      "Global search across all customers and entries",
      "Running due balance calculated automatically",
    ))
    #feature-box("Reminders & Notifications", (
      "Scheduled local notifications for due dates",
      "One-tap, pre-filled SMS reminders (no gateway cost)",
      "Full reminder history log per customer",
    ))
  ],
  [
    #feature-box("Security & Privacy", (
      "PIN and fingerprint / biometric app lock",
      "Escalating lockout after failed PIN attempts",
      "Phone-number based authentication",
    ))
    #feature-box("Reports, Backup & Export", (
      "PDF receipts and customer statements",
      "Business reports with interactive charts",
      "CSV export / import with Bangla headers",
      "Optional Firebase cloud backup & restore",
    ))
  ]
)

= Technology Stack
#block(
  width: 100%,
  fill: light-bg,
  stroke: 0.6pt + light-border,
  radius: 5pt,
  inset: 10pt,
)[
  - Flutter (Android, Windows, Linux) with a Bangla (Noto Serif Bengali) font pipeline
  - Firebase — Authentication, Firestore, Storage, Crashlytics
  - flutter_local_notifications + timezone for scheduled due-date reminders
  - local_auth for fingerprint / biometric app lock, crypto for PIN hashing
  - pdf & printing for receipt and report generation, share_plus for sharing
  - fl_chart for dashboard analytics, csv for data export / import
]
