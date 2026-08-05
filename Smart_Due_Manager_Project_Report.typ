

#let serif = "Liberation Serif"
#let mono = "Liberation Mono"

#set document(title: "Smart Due Manager — Project Report", author: "Dipjoy Bal")
#set text(font: serif, size: 11pt, lang: "en")
#set par(justify: true, leading: 0.62em)
#set heading(numbering: none)

// ---------- manual figure / table caption counters ----------
#let fig-counter = counter("fig")
#let tbl-counter = counter("tbl")

#let fig-caption(cap) = {
  fig-counter.step()
  align(center, context text(size: 10pt)[Figure #fig-counter.display(): #cap])
}
#let tbl-caption(cap) = {
  tbl-counter.step()
  align(center, context text(size: 10pt)[Table #tbl-counter.display(): #cap])
}

#let ascii-block(body) = {
  align(center, block(
    inset: 8pt,
    breakable: false,
    text(font: (mono, "DejaVu Sans Mono"), size: 8pt, body),
  ))
}

#let placeholder-box(body) = {
  block(
    width: 100%,
    breakable: false,
    stroke: 0.6pt + black,
    inset: 14pt,
    align(center, text(style: "italic", size: 10pt, body)),
  )
}

// ============================================================
// COVER PAGE
// ============================================================
#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2cm, left: 2.2cm, right: 2.2cm),
  header: none,
  footer: none,
)

#box(
  width: 76pt, height: 76pt, radius: 4pt,
  stroke: 1.5pt + black,
  align(center + horizon, text(font: serif, weight: "bold", size: 15pt)[PSTU])
)
#v(6pt)
#text(size: 16pt, weight: "bold")[Patuakhali Science and Technology University] \
#text(size: 12pt)[Faculty of Computer Science and Engineering]

#v(6pt)
#line(length: 100%, stroke: 0.6pt + black)
#v(8pt)

#text(size: 15pt, weight: "bold")[Software Development Project – I]
#v(4pt)
#text(size: 12pt, weight: "bold")[Project Report]

#v(6pt)
#line(length: 100%, stroke: 0.6pt + black)

#v(1.4cm)
#align(center)[
  #text(size: 22pt, weight: "bold")[Smart Due Manager]
  #v(4pt)
  #text(size: 11.5pt, style: "italic")[Customer Due \& Payment Management with Automated SMS Reminders]
]
#v(1.4cm)

#text(size: 11pt)[*Project Title* : Smart Due Manager (Customer Due and Payment Management System)] \
#text(size: 11pt)[*Submission Date* : 04, August 2026]

#v(6pt)
#line(length: 100%, stroke: 0.6pt + black)

#v(10pt)
#table(
  columns: (1fr, 1fr),
  stroke: 0.7pt + black,
  inset: 10pt,
  [
    #text(weight: "bold")[Submitted from,]
    #v(6pt)
    *Dipjoy Bal* \
    *ID* : 2102053 \
    *Reg* : 10180 \
    Department of Computer Science and Information Technology
  ],
  [
    #text(weight: "bold")[Submitted to,]
    #v(6pt)
    + *Dr. Md. Samsuzzaman* \
      Professor, \
      Department of Computer and Communication Engineering, \
      Patuakhali Science and Technology University.
    + *Sarna Majumder* \
      Associate Professor, \
      Department of Computer and Communication Engineering, \
      Patuakhali Science and Technology University.
  ],
)

#pagebreak()

// ============================================================
// CONTENTS
// ============================================================
#set page(
  paper: "a4",
  margin: (top: 2.4cm, bottom: 2.2cm, left: 2.3cm, right: 2.3cm),
  header: none,
  footer: context align(center, text(size: 10pt)[#counter(page).display()]),
)

#text(size: 18pt, weight: "bold")[Contents]
#v(6pt)
#outline(title: none, indent: auto, depth: 3)

#pagebreak()

// ============================================================
// MAIN CONTENT
// ============================================================
#set heading(numbering: "1.")

#show heading.where(level: 1): it => {
  v(14pt, weak: true)
  text(size: 15pt, weight: "bold")[
    #if it.numbering != none [#counter(heading).display(it.numbering) ]#it.body
  ]
  v(10pt, weak: true)
}
#show heading.where(level: 2): it => {
  v(10pt, weak: true)
  text(size: 12.5pt, weight: "bold")[
    #if it.numbering != none [#counter(heading).display(it.numbering) ]#it.body
  ]
  v(6pt, weak: true)
}

#align(center, text(size: 17pt, weight: "bold")[Smart Due Manager])
#v(8pt)

// ------------------------------------------------------------
= Introduction

Across small towns and neighborhoods in Bangladesh, a large share of retail commerce — grocery ("মুদি") shops, pharmacies, and other local vendors — runs partly on informal credit, with customer dues tracked in a handwritten ledger ("বাকির খাতা"). This manual approach is slow to search, offers no automated reminders, and provides no backup if the ledger is lost or damaged. To address this, *Smart Due Manager* is proposed — a cross-platform mobile application, built with Flutter and Firebase, that digitizes customer due tracking and payment recording and, uniquely, reminds customers automatically through SMS sent directly from the shop owner's own phone, without requiring a paid third-party SMS gateway.

// ------------------------------------------------------------
= Objectives

The main objective of this project is to develop a mobile-based system that allows:

+ Easy and secure recording of customers, payments, and outstanding dues
+ Automated, schedulable SMS reminders sent directly from the owner's own device
+ Transparent, auditable payment history with PDF reports and customer statements
+ Secure, isolated multi-user data storage, protected by an app-lock and database security rules
+ A fully Bengali-localized experience with a customizable SMS reminder template

// ------------------------------------------------------------
= Problem Statement

Managing customer credit and due collection in small shops is often a manual, disorganized, and inefficient process. Shop owners typically rely on a paper ledger, memory, or phone calls to track balances and remind customers — which leads to:

+ Slow, error-prone lookup of a customer's current balance
+ No automated way to remind a customer that a payment is due
+ No backup — a lost or damaged ledger means lost records
+ Difficulty producing a printable/shareable proof of transactions
+ No way to safely share the ledger with staff without risking tampering

// ------------------------------------------------------------
= Related Work

+ *Khatabook* — A widely used South Asian digital "খাতা" (credit-book) app that lets shopkeepers record customer dues digitally. \
  _Limitation:_ Reminder delivery is generally built around the customer also having the Khatabook app (or a linked messaging integration under its own paid plans), rather than a plain SMS sent directly from the shop owner's own SIM at no extra cost.#footnote(numbering: "[1]")[Khatabook. Accessed: Aug. 04, 2026. Online. Available: https://khatabook.com/]

+ *OkCredit* — A popular digital credit-book and payment-reminder app for small merchants. \
  _Limitation:_ Primarily oriented around the Indian market and UPI-based payments; less tailored to Bangladeshi currency, bKash/Nagad payment methods, or a fully Bengali, business-branded SMS template.#footnote(numbering: "[1]")[OkCredit. Accessed: Aug. 04, 2026. Online. Available: https://okcredit.in/]

+ *Generic accounting / invoicing software* (e.g. spreadsheet-based tools or general invoicing apps) — Can record transactions digitally. \
  _Limitation:_ Built around an invoice-per-transaction workflow rather than a simple running "due" balance per customer, and with no built-in SMS reminder automation.

+ *Manual Systems (Paper Ledger / Excel / Phone Calls)* — Most small shop owners in Bangladesh still track dues on paper, in a spreadsheet, or by calling customers. \
  _Limitation:_ Prone to human error, offers no search or backup, no automated reminders, and no digital proof of transactions.

// ------------------------------------------------------------
= Scope

Smart Due Manager is developed as a cross-platform mobile application using Flutter, with Android as the primary target platform because two of its core features — direct SMS sending and background SMS scheduling — depend on Android-specific telephony and background-execution APIs. The backend (authentication, database, file storage, and crash reporting) is provided by Google Firebase. The project covers customer and payment management, reminders and SMS automation, PDF reporting, CSV backup, settings/theming, and an application-level lock screen. It is designed to be simple, scalable, and localized, making it suitable for individual shop owners and small retail businesses in Bangladesh. Point-of-sale/inventory management is intentionally out of scope.

// ------------------------------------------------------------
= Key Features

+ *Customer \& Payment Management* \
  Add, edit, and search customer profiles; the outstanding due balance updates automatically with every payment or new due entry, and a full payment history is kept per customer (amount, method — bKash, Nagad, Hand Cash, or Bank — and an optional receipt photo).

+ *Automated SMS Reminders* \
  Set a reminder date for a customer and the app sends an SMS directly from the owner's own SIM — either immediately or automatically in the background at the scheduled time — with retry-on-failure logic and a per-customer send log.

+ *PDF Reports \& Customer Statements* \
  Generate daily, weekly, or monthly collection reports, and a printable/shareable PDF statement for any individual customer.

+ *CSV Backup \& Restore* \
  Export all customers to a CSV file and share it as a backup; re-import from CSV later, with automatic duplicate detection by phone number.

+ *Archive \& Restore Customers* \
  Soft-delete (archive) a customer without losing their history, and restore them — or permanently delete a customer and all related records — at any time.

+ *App Lock \& Biometric Security* \
  Protect the app with a PIN (hashed using PBKDF2-HMAC-SHA256, never stored in plain text) or biometric unlock (fingerprint/face), with an escalating lockout after repeated failed attempts.

+ *Multi-User Data Isolation* \
  Every customer record is scoped to its owner and enforced by Firestore Security Rules, so multiple shop owners can safely share the same backend without seeing each other's data.

+ *Customizable Settings \& Theming* \
  Choose a dark or light theme and an accent color, set the currency symbol, adjust the app-wide font scale, and configure a business profile (name, address, logo) used across reports.

+ *Bengali Localization* \
  A fully Bengali-capable interface with a bundled Bengali font, plus a customizable SMS reminder template supporting placeholders such as `{name}`, `{amount}`, `{due_date}`, and `{business_name}`.

// ------------------------------------------------------------
= Methodology

The development of Smart Due Manager followed an Agile approach using Iterative and Incremental Development, enabling rapid prototyping, continuous feedback, and flexible improvement based on real usage.

== Step-by-Step Development Methodology

+ *Requirement Analysis*
  + Study the core workflow of a small shop owner tracking customer dues on paper
  + Identify core modules — customer/payment management, reminders, reports, backup, security
  + Finalize functional and non-functional requirements
  + Define user stories for the shop-owner actor

+ *System Design*
  + Design a layered architecture (presentation, state, service, repository, backend)
  + Define the Cloud Firestore schema for users, customers, payments, reminders, and SMS logs
  + Plan per-user data isolation via an `ownerId` field and Firestore Security Rules

+ *Technology Stack Selection*
  + Frontend: Flutter (Android primary target; Linux/Windows/Web build targets available)
  + Backend: Firebase — Authentication, Cloud Firestore, Storage, Crashlytics
  + Background execution: Workmanager, to schedule SMS independent of the app's lifecycle
  + SMS: another_telephony, for direct on-device SMS sending
  + PDF generation: the `pdf` and `printing` Dart packages
  + Security: `crypto` (PBKDF2-HMAC-SHA256) for PIN hashing, `local_auth` for biometrics

+ *Implementation and Testing*
  + Features implemented and validated incrementally, module by module
  + Automated unit tests cover the PIN-hashing service; remaining modules verified through manual functional testing against a live Firebase project

*Notes*
+ Iterations shipped incremental features (auth → customer/payment → reminders/SMS → reports/backup → security) for early testing
+ Security practices include PBKDF2-hashed PINs, constant-time verification, escalating lockout on repeated failures, and `ownerId`-scoped Firestore Security Rules

// ------------------------------------------------------------
= Visual Models

== Flow Chart Diagram

#ascii-block[```mermaid
flowchart TD
    Start(["App Start"]) --> Splash["Splash Screen"]
    Splash --> AuthCheck{"Logged In?"}

    AuthCheck -- No --> LoginScreen["Login Screen"]
    LoginScreen -- New user --> RegisterScreen["Register Screen"]
    RegisterScreen --> LoginScreen
    LoginScreen -- Sign-in success --> LockCheck{"App Lock Enabled?"}
    AuthCheck -- Yes --> LockCheck

    LockCheck -- Yes --> AppLockScreen["App Lock Screen
PIN / Biometric"]
    AppLockScreen --> PinOk{"PIN / Biometric
Correct?"}
    PinOk -- No --> Lockout["Record Failed Attempt
Escalating Lockout"]
    Lockout --> AppLockScreen
    PinOk -- Yes --> Home["Home Dashboard"]
    LockCheck -- No --> Home

    Home --> AllCustomers["All Customers"]
    Home --> AddCustomer["Add Customer"]
    Home --> ReportsScreen["Collection Reports"]
    Home --> SettingsScreen["Settings"]
    Home --> Logout["Logout"] --> LoginScreen

    AddCustomer --> SaveCustomer["Save Customer
ownerId = uid"]
    SaveCustomer --> AllCustomers

    AllCustomers --> CustomerDetail["Customer Detail"]
    CustomerDetail --> AddPayment["Add Payment"]
    CustomerDetail --> SetReminder["Set Reminder"]
    CustomerDetail --> CustomerPdf["Customer PDF Statement"]
    CustomerDetail --> ArchiveAction["Archive Customer"]
    ArchiveAction --> ArchivedScreen["Archived Customers"]
    ArchivedScreen -- Restore --> AllCustomers
    ArchivedScreen -- Delete --> Deleted["Removed Permanently"]

    AddPayment --> EntryType{"Payment or
New Due?"}
    EntryType -- Payment --> Method["Choose Method
bKash / Nagad / Cash / Bank"]
    Method --> SavePayment["Save Payment
Update totalDue"]
    EntryType -- New Due --> SavePayment
    SavePayment --> CustomerDetail

    SetReminder --> When{"Send Now or
Schedule?"}
    When -- Now --> SendNow["Send SMS Now"]
    SendNow --> LogSms["Log to smsLogs"]
    When -- Schedule --> Queue["Register Workmanager Task"]
    Queue --> WaitBg["Wait Until Scheduled Time
app may be closed"]
    WaitBg --> BgSend["Background: Send SMS
retry up to 3x"]
    BgSend --> SentOk{"SMS Sent?"}
    SentOk -- Yes --> LogSms
    SentOk -- No --> FailLog["Log Failure"]
    LogSms --> CustomerDetail

    CustomerPdf --> GeneratePdf["Generate PDF"]
    GeneratePdf --> ShareOrPrint["Share / Print"]

    ReportsScreen --> Period{"Daily / Weekly /
Monthly?"}
    Period --> Aggregate["Aggregate Payments
in Range"]
    Aggregate --> ExportPdf["Export Report PDF"]

    SettingsScreen --> Profile["Theme / Currency /
Business Profile"]
    SettingsScreen --> SmsTpl["Edit SMS Template"]
    SettingsScreen --> EnableLock["Enable App Lock
Set PIN"]
    SettingsScreen --> Backup["Export CSV Backup"]
    SettingsScreen --> RestoreCsv["Import CSV"]
    RestoreCsv --> Dedup["Skip Duplicate Phones
Import Rest"]
    Dedup --> AllCustomers
```]
#fig-caption[User Flow Chart of Smart Due Manager — Mermaid source]

The Mermaid source above traces the app's user flow from launch through authentication and the app lock, into the home dashboard, and out to each major feature: customer and payment management, reminder scheduling with immediate vs. background-scheduled SMS delivery, PDF report/statement generation, and settings (theming, SMS template, app lock setup, and CSV backup/restore). Render it with any Mermaid-compatible tool (e.g. the Mermaid Live Editor at #link("https://mermaid.live") or the Mermaid VS Code extension) to produce the diagram image, then paste that image in place of this listing before final submission.

== ERD (Entity Relationship Diagram)

#ascii-block[```
┌─────────────────┐   1        N   ┌───────────────────────┐
│       User        │ ──────────────▶│        Customer         │
│ uid (PK)            │                │ id (PK)                  │
│ name, phone          │                │ ownerId (FK → User)      │
│ settings {theme,     │                │ name, phone, address     │
│  currency, sms tpl}   │                │ totalDue, isHidden       │
└─────────────────┘                └───────────┬───────────┘
                                                │ 1
                              ┌─────────────────┼─────────────────┐
                              │ N                │ N                │ N
                     ┌────────▼────────┐ ┌───────▼───────┐ ┌───────▼───────┐
                     │     Payment       │ │    Reminder     │ │     SmsLog      │
                     │ id (PK)            │ │ id (PK)          │ │ id (PK)          │
                     │ customerId (FK)    │ │ reminderDate     │ │ sentAt           │
                     │ amount, type        │ │ createdAt        │ │ type             │
                     │ paymentMethod, date  │ │ status           │ │                  │
                     └────────────────┘ └───────────────┘ └───────────────┘
```]
#fig-caption[Entity Relationship Diagram of Smart Due Manager]

The above figure illustrates the entity-relationship model backing Smart Due Manager on Cloud Firestore. Each *User* owns many *Customer* records (scoped by an `ownerId` foreign key), and each *Customer* in turn owns many *Payment*, *Reminder*, and *SmsLog* records stored as Firestore subcollections. The ERD helps in understanding the data model and how the entities relate to one another.

== Timeline (Gantt Chart)

The base timeline for the development of Smart Due Manager is as follows,

#table(
  columns: (2.2fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
  stroke: 0.6pt + black,
  inset: 5pt,
  align: center,
  [*Task*], [*Wk 1-2*], [*Wk 3-4*], [*Wk 5-6*], [*Wk 7-8*], [*Wk 9*], [*Wk 10*], [*Wk 11*], [*Wk 12*],
  [Requirements \& UI Mockup], [✓], [✓], [], [], [], [], [], [],
  [Firebase Auth \& Firestore setup], [], [✓], [✓], [], [], [], [], [],
  [Customer \& payment CRUD], [], [], [✓], [✓], [], [], [], [],
  [Reminder \& background SMS (WorkManager)], [], [], [], [✓], [✓], [], [], [],
  [PDF reports \& CSV backup], [], [], [], [], [✓], [✓], [], [],
  [App lock (PIN/biometric) \& security rules], [], [], [], [], [], [✓], [✓], [],
  [UI polish, Bengali localization \& docs], [], [], [], [], [], [], [✓], [✓],
  [Final testing \& deployment], [], [], [], [], [], [], [], [✓],
)
#tbl-caption[Development Timeline of Smart Due Manager]

The timeline is divided into 12 weeks, with specific tasks allocated to each period, describing an approximate/planned schedule for the whole development process.

== UI/UX Design

#placeholder-box[Insert UI/UX wireframes or mockup screenshots here before final submission.]
#fig-caption[UI/UX Mockups]

== App screens

#placeholder-box[Insert screenshots: Login / Registration screen and Home dashboard screen.]
#fig-caption[Login/Register and Home Dashboard screens]

#placeholder-box[Insert screenshots: Add/Detail Customer screen and Add Payment screen.]
#fig-caption[Customer Detail and Add Payment screens]

#placeholder-box[Insert screenshots: Reminder scheduling screen and Customer PDF report screen.]
#fig-caption[Reminder Scheduling and PDF Report screens]

#placeholder-box[Insert screenshots: Settings screen and App Lock screen.]
#fig-caption[Settings and App Lock screens]

// ------------------------------------------------------------
= Limitations

+ *Android-Only SMS Automation* \
  Direct SMS sending is an Android-only capability; the automated reminder feature has no equivalent on iOS, where apps cannot send SMS programmatically, and no equivalent yet on desktop/web builds.

+ *SIM-Dependent Delivery Cost* \
  Because SMS is sent through the shop owner's own SIM, delivery depends on that device having network/SIM connectivity and incurs the operator's normal per-SMS cost — there is no bulk/cloud SMS gateway fallback.

+ *Device-Local App Lock* \
  The app-lock PIN protects the local app session but is device-local; it does not, by itself, encrypt data at rest beyond what Firestore/Android already provide.

+ *No Analytics Dashboard* \
  Reporting is currently limited to tabular PDF exports; there is no in-app chart/graph analytics dashboard.

+ *Single Currency Setting* \
  The project currently supports a single currency symbol setting rather than true multi-currency accounting.

// ------------------------------------------------------------
= Future Plans

+ *Cloud SMS Gateway Fallback* \
  Integrate an optional cloud SMS gateway as a fallback when the owner's device is offline, to complement the current on-device sending.

+ *Analytics Dashboard* \
  Add a visual analytics dashboard (collection trends, top overdue customers) using charts.

+ *Multi-Staff, Role-Based Accounts* \
  Support multiple staff accounts per business with role-based permissions, rather than one owner per dataset.

+ *Encrypted Backup \& Biometric-Gated Export* \
  Add end-to-end encrypted backups and optional local biometric-gated data export.

+ *Expanded Automated Testing* \
  Extend automated test coverage to the repository and service layers using the Firestore emulator.

+ *Multi-Language Expansion* \
  Add further regional language options beyond Bengali and English for broader accessibility.

// ------------------------------------------------------------
= Result

Despite the limitations, the system achieves significant success in solving real-life problems of customer due and payment management:

+ *Successful Customer Due Tracking* \
  Owners can now add, search, and manage customer profiles and running due balances in a structured digital format.

+ *Reliable Automated SMS Reminders* \
  Scheduled reminders continue to fire and deliver correctly even after the app is fully closed, since the SMS-send task runs through the operating system's background scheduler.

+ *Transparent Payment History* \
  Every payment and due entry is preserved in an auditable history, with printable/shareable PDF statements and collection reports.

+ *Secure Multi-User Data Isolation* \
  Firestore Security Rules independently enforce that each user can only read or write their own customers, verified by testing with two separate accounts on the same backend.

+ *Effective App Lock Protection* \
  The PIN (PBKDF2-hashed) and biometric app lock, together with escalating lockout, successfully prevent casual unauthorized access on a shared or lost device.

+ *Portable CSV Backup* \
  Customers can be exported to and re-imported from CSV, giving owners a way to move data off-device that a paper ledger cannot provide.

// ------------------------------------------------------------
#heading(level: 1, numbering: none)[References]

+ Khatabook. Accessed: Aug. 04, 2026. [Online]. Available: #link("https://khatabook.com/")
+ OkCredit. Accessed: Aug. 04, 2026. [Online]. Available: #link("https://okcredit.in/")
+ "Flutter." [Online]. Available: #link("https://flutter.dev/")
+ "Firebase Documentation." [Online]. Available: #link("https://firebase.google.com/docs")
+ "Cloud Firestore Security Rules Reference." [Online]. Available: #link("https://firebase.google.com/docs/firestore/security/get-started")
+ pub.dev, "another_telephony." [Online]. Available: #link("https://pub.dev/packages/another_telephony")
+ pub.dev, "workmanager." [Online]. Available: #link("https://pub.dev/packages/workmanager")
+ pub.dev, "pdf" and "printing." [Online]. Available: #link("https://pub.dev/packages/pdf"), #link("https://pub.dev/packages/printing")
+ pub.dev, "crypto." [Online]. Available: #link("https://pub.dev/packages/crypto")
+ RFC 8018, "PKCS #5: Password-Based Cryptography Specification Version 2.1 (PBKDF2)," IETF, 2017.

#v(2cm)
#align(center, text(weight: "bold")[THE END])
