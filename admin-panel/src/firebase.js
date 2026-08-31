import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'
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
export const auth = getAuth(app)
export const db = getFirestore(app)
export const storage = getStorage(app)
