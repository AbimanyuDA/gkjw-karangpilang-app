import { createContext, useContext } from 'react'
import type { Session } from './api'

export interface AuthState {
  user: Session | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  /** true bila keluar karena sesi habis (untuk pesan di halaman login). */
  expired: boolean
}

export const AuthContext = createContext<AuthState | null>(null)

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth harus di dalam AuthProvider')
  return ctx
}
