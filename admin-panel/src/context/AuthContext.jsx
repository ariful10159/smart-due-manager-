import { createContext, useContext, useEffect, useState } from 'react'
import { onAuthStateChanged, signOut as firebaseSignOut } from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, db } from '../firebase'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [isAdmin, setIsAdmin] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    return onAuthStateChanged(auth, async (firebaseUser) => {
      setUser(firebaseUser)
      if (firebaseUser) {
        try {
          const adminDoc = await getDoc(doc(db, 'admins', firebaseUser.uid))
          setIsAdmin(adminDoc.exists())
        } catch {
          setIsAdmin(false)
        }
      } else {
        setIsAdmin(false)
      }
      setLoading(false)
    })
  }, [])

  const signOut = () => firebaseSignOut(auth)

  return (
    <AuthContext.Provider value={{ user, isAdmin, loading, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider')
  return ctx
}
