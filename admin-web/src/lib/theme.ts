import { useCallback, useState } from 'react'

export type ThemeMode = 'system' | 'light' | 'dark'
const KEY = 'gkjw-admin-theme' // dibaca juga oleh public/theme-init.js

function read(): ThemeMode {
  try {
    const v = localStorage.getItem(KEY)
    return v === 'light' || v === 'dark' ? v : 'system'
  } catch {
    return 'system'
  }
}

/** Tema admin: ikuti sistem (default), terang, atau gelap — sama seperti di aplikasi. */
export function useTheme(): [ThemeMode, (mode: ThemeMode) => void] {
  const [mode, setMode] = useState<ThemeMode>(read)
  const apply = useCallback((next: ThemeMode) => {
    setMode(next)
    const root = document.documentElement
    if (next === 'system') delete root.dataset.theme
    else root.dataset.theme = next
    try {
      if (next === 'system') localStorage.removeItem(KEY)
      else localStorage.setItem(KEY, next)
    } catch {
      /* penyimpanan diblokir: tema tetap berlaku selama halaman terbuka */
    }
  }, [])
  return [mode, apply]
}
