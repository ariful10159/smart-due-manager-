# Smart Due — Admin Panel

React (Vite + Tailwind) web admin panel for the Smart Due Manager Flutter app. Connects to the
same Firebase project (`due-manager-10dd1`) — Auth, Firestore, Storage.

## One-time setup (do this once, manually, before first login)

1. **Create an admin login account** — Firebase Console → Authentication → Users → Add user
   (email + password). This is a plain Firebase Auth account, separate from the phone-based
   accounts regular shopkeepers use in the Flutter app.
2. **Mark that account as an admin** — Firebase Console → Firestore Database → Data → create a
   document in a collection named `admins`, with the **document ID set to that user's UID**
   (copy the UID from the Authentication tab). The document's fields don't matter much; e.g.:
   ```
   collection: admins
   document id: <uid>
   fields: { email: "you@example.com", createdAt: <timestamp> }
   ```
   This step must be done manually (via Console or `firebase firestore` CLI) — `firestore.rules`
   deliberately blocks all client writes to `admins/*`, so there is no way to self-promote to
   admin from the app or the panel itself.
3. **Deploy the updated security rules** (if you haven't already), from the repo root:
   ```
   firebase deploy --only firestore:rules,storage:rules
   ```

## Run locally

```
cd admin-panel
npm install
npm run dev
```

Then open the printed local URL and sign in with the admin email/password from step 1.

## What it can do

- **Users** — list all registered shopkeepers, drill into one to see their customers.
- Per customer: expand to see payment history, edit or delete a customer or a payment.
- **Reset PIN** — clears the user's app-lock PIN/biometric lock (they'll be prompted to set a
  new PIN next time they open the app).
- **Disable / enable account** — sets a `disabled` flag on the user; the Flutter app checks this
  on login and blocks/signs the user out while disabled. This does **not** touch the underlying
  Firebase Auth account (a full account-level disable/delete would require Cloud Functions with
  the Admin SDK, which this project doesn't have set up).
- **Delete all data** — permanently deletes a user's Firestore data (profile, customers,
  payments, reminders, notebooks). The Auth account itself is left intact.
- **Announcement** — set a title/message banner that shows at the top of every user's home
  screen in the Flutter app while marked active.
