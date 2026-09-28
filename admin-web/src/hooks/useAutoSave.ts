import { useCallback, useEffect, useRef, useState } from 'react'

export type AutoSaveStatus = 'idle' | 'pending' | 'saving' | 'saved' | 'error'

interface Options {
  /** Isi form saat ini dalam bentuk teks (mis. JSON payload); berubah = ada perubahan. */
  snapshot: string
  /** Menyimpan snapshot tertentu. Lempar error bila gagal. */
  save: (snapshot: string) => Promise<void>
  /** Tunda penyimpanan (mis. selama foto masih diunggah). */
  blocked?: boolean
  /** Jeda setelah perubahan terakhir sebelum menyimpan otomatis. */
  delay?: number
}

export interface AutoSave {
  status: AutoSaveStatus
  dirty: boolean
  savedAt: Date | null
  error: string | null
  saveNow: () => Promise<void>
}

/**
 * Simpan otomatis: setiap perubahan disimpan sesaat setelah admin berhenti mengetik.
 * Perubahan yang terjadi saat penyimpanan berjalan disimpan pada putaran berikutnya.
 */
export function useAutoSave({ snapshot, save, blocked = false, delay = 1200 }: Options): AutoSave {
  const [saved, setSaved] = useState(snapshot)
  // Status proses terakhir; "pending" diturunkan dari ada/tidaknya perubahan.
  const [phase, setPhase] = useState<Exclude<AutoSaveStatus, 'pending'>>('idle')
  const [failed, setFailed] = useState<string | null>(null) // snapshot yang gagal disimpan
  const [savedAt, setSavedAt] = useState<Date | null>(null)
  const [error, setError] = useState<string | null>(null)
  const inFlight = useRef(false)
  const latest = useRef(snapshot)
  useEffect(() => {
    latest.current = snapshot
  }, [snapshot])
  const dirty = snapshot !== saved

  const saveNow = useCallback(async () => {
    const sent = latest.current
    if (inFlight.current || sent === saved) return
    inFlight.current = true
    setPhase('saving')
    setError(null)
    try {
      await save(sent)
      setSaved(sent)
      setSavedAt(new Date())
      setFailed(null)
      setPhase('saved')
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Gagal menyimpan.')
      setFailed(sent)
      setPhase('error')
    } finally {
      inFlight.current = false
    }
  }, [save, saved])

  useEffect(() => {
    if (!dirty || blocked || snapshot === failed) return
    const timer = setTimeout(() => void saveNow(), delay)
    return () => clearTimeout(timer)
    // `saved` ikut memicu: perubahan saat menyimpan dijadwalkan ulang setelah selesai.
  }, [snapshot, saved, failed, dirty, blocked, delay, saveNow])

  // Ingatkan sebelum menutup/memuat ulang tab bila masih ada perubahan belum tersimpan.
  useEffect(() => {
    if (!dirty) return
    const warn = (e: BeforeUnloadEvent) => e.preventDefault()
    window.addEventListener('beforeunload', warn)
    return () => window.removeEventListener('beforeunload', warn)
  }, [dirty])

  const status: AutoSaveStatus =
    phase === 'saving' || (phase === 'error' && snapshot === failed) ? phase : dirty ? 'pending' : phase
  return { status, dirty, savedAt, error: status === 'error' ? error : null, saveNow }
}
