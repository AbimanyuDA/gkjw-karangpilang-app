import { useEffect, useRef, type ReactNode } from 'react'
import { X } from 'lucide-react'

/** Panel geser dari kanan untuk form tambah/ubah. Memakai <dialog> bawaan: fokus terkunci & Esc menutup. */
export function Drawer({ title, eyebrow, onClose, children }: { title: string; eyebrow?: string; onClose: () => void; children: ReactNode }) {
  const ref = useRef<HTMLDialogElement>(null)
  useEffect(() => {
    const d = ref.current
    if (d && !d.open) d.showModal()
    return () => d?.close()
  }, [])
  return (
    <dialog ref={ref} className="drawer" aria-labelledby="drawer-title" onCancel={(e) => (e.preventDefault(), onClose())}>
      <header className="drawer-head">
        <div>
          {eyebrow && <div className="eyebrow">{eyebrow}</div>}
          <h2 id="drawer-title">{title}</h2>
        </div>
        <button type="button" className="btn btn-ghost btn-icon" onClick={onClose} aria-label="Tutup">
          <X size={20} />
        </button>
      </header>
      <div className="drawer-body">{children}</div>
    </dialog>
  )
}

interface ConfirmProps {
  title: string
  message: string
  confirmLabel: string
  busy?: boolean
  onConfirm: () => void
  onCancel: () => void
}

export function ConfirmDialog({ title, message, confirmLabel, busy, onConfirm, onCancel }: ConfirmProps) {
  const ref = useRef<HTMLDialogElement>(null)
  useEffect(() => {
    const d = ref.current
    if (d && !d.open) d.showModal()
    return () => d?.close()
  }, [])
  return (
    <dialog ref={ref} className="confirm" aria-labelledby="confirm-title" onCancel={(e) => (e.preventDefault(), onCancel())}>
      <h2 id="confirm-title">{title}</h2>
      <p>{message}</p>
      <div className="form-actions">
        <button className="btn btn-secondary" onClick={onCancel} disabled={busy} autoFocus>
          Batal
        </button>
        <button className="btn btn-danger" onClick={onConfirm} disabled={busy}>
          {busy && <span className="spinner" aria-hidden />}
          {confirmLabel}
        </button>
      </div>
    </dialog>
  )
}
