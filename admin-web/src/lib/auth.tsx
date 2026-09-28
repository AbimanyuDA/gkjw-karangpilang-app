import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import { UNAUTHORIZED_EVENT, login as apiLogin, session, type Session } from './api'
import { AuthContext, useAuth } from './authContext'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<Session | null>(() => session.get())
  const [expired, setExpired] = useState(false)
  const queryClient = useQueryClient()

  const logout = useCallback(() => {
    session.clear()
    queryClient.clear()
    setUser(null)
  }, [queryClient])

  useEffect(() => {
    const onUnauthorized = () => {
      setExpired(true)
      logout()
    }
    window.addEventListener(UNAUTHORIZED_EVENT, onUnauthorized)
    return () => window.removeEventListener(UNAUTHORIZED_EVENT, onUnauthorized)
  }, [logout])

  const login = useCallback(async (email: string, password: string) => {
    const s = await apiLogin(email, password)
    setExpired(false)
    setUser(s)
  }, [])

  const value = useMemo(() => ({ user, login, logout, expired }), [user, login, logout, expired])
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function RequireAuth({ children }: { children: ReactNode }) {
  const { user } = useAuth()
  const location = useLocation()
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname + location.search }} />
  return <>{children}</>
}
