import { createContext, useContext, useEffect, useState } from 'react'
import { onAuthStateChanged, signOut as firebaseSignOut } from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, db } from '../firebase'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [isAdmin, setIsAdmin] = useState(false)
  // Missing `role` field (pre-migration admin docs) is treated as 'super' — matches the
  // same fallback used server-side in functions/index.js.
  const [role, setRole] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    return onAuthStateChanged(auth, async (firebaseUser) => {
      setUser(firebaseUser)
      if (firebaseUser) {
        try {
          const adminDoc = await getDoc(doc(db, 'admins', firebaseUser.uid))
          setIsAdmin(adminDoc.exists())
          setRole(adminDoc.exists() ? (adminDoc.data().role === 'staff' ? 'staff' : 'super') : null)
        } catch {
          setIsAdmin(false)
          setRole(null)
        }
      } else {
        setIsAdmin(false)
        setRole(null)
      }
      setLoading(false)
    })
  }, [])

  const signOut = () => firebaseSignOut(auth)
  const isSuperAdmin = isAdmin && role === 'super'

  return (
    <AuthContext.Provider value={{ user, isAdmin, role, isSuperAdmin, loading, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider')
  return ctx
}
