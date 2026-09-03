import * as Sentry from '@sentry/react'

// VITE_SENTRY_DSN সেট না থাকলে (Sentry-তে project বানানোর আগে) নিরাপদে skip করা হয় —
// নাহলে dev/local build ভেঙে যেত। DSN বসিয়ে rebuild করলেই error reporting চালু হয়ে
// যাবে, কোড বদলাতে হবে না। Init হয়ে গেলে unhandled error/promise rejection automatic
// ভাবেই ধরা পড়ে — আলাদা কোনো global handler লাগে না।
const dsn = import.meta.env.VITE_SENTRY_DSN

if (dsn) {
  Sentry.init({
    dsn,
    environment: import.meta.env.MODE,
    // শুধু error tracking — performance tracing/session replay চালু করা হয়নি,
    // ফ্রি tier-এর quota এভাবে error-এর জন্যই থাকে।
    tracesSampleRate: 0,
  })
}

export { Sentry }
