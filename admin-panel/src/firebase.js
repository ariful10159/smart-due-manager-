import { initializeApp } from 'firebase/app'
import { initializeAppCheck, ReCaptchaV3Provider } from 'firebase/app-check'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'
import { getFunctions } from 'firebase/functions'
import { getStorage } from 'firebase/storage'

// Same Firebase project the Flutter app uses (see lib/firebase_options.dart, web config).
// This is not a secret — access control lives in firestore.rules / storage.rules.
const firebaseConfig = {
  apiKey: 'AIzaSyA1Xh7WPLgpxm-_7ahXXCFwFkPmLUJIh38',
  authDomain: 'due-manager-10dd1.firebaseapp.com',
  projectId: 'due-manager-10dd1',
  storageBucket: 'due-manager-10dd1.firebasestorage.app',
  messagingSenderId: '580307087717',
  appId: '1:580307087717:web:aa1df2f96e30afba59318c',
  measurementId: 'G-9CLPW274DQ',
}

export const app = initializeApp(firebaseConfig)

// App Check — যাতে Firestore/Storage/Cloud Functions শুধু এই admin panel থেকেই কল হয়,
// stolen Firebase config দিয়ে সরাসরি script/curl হিট করা না যায়। VITE_RECAPTCHA_SITE_KEY
// সেট না থাকলে (Firebase Console-এ App Check-এ web app রেজিস্টার করার আগে) নিরাপদে স্কিপ
// করা হয় — নাহলে dev/local build ভেঙে যেত।
if (import.meta.env.DEV) {
  // Firebase Console-এ App Check > Apps > (এই web app) > Manage debug tokens এ
  // যোগ করা একটা টোকেন ছাড়া local dev-এ App Check request গুলো block হয়ে যাবে।
  self.FIREBASE_APPCHECK_DEBUG_TOKEN = true
}

const recaptchaSiteKey = import.meta.env.VITE_RECAPTCHA_SITE_KEY
export const appCheck = recaptchaSiteKey
  ? initializeAppCheck(app, {
      provider: new ReCaptchaV3Provider(recaptchaSiteKey),
      isTokenAutoRefreshEnabled: true,
    })
  : null

export const auth = getAuth(app)
export const db = getFirestore(app)
export const storage = getStorage(app)
export const functions = getFunctions(app)
