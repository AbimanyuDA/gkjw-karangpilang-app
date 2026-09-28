import { useState, type FormEvent } from 'react'
import { useToast } from '../lib/toast'
import { ApiError, request } from '../lib/api'
import { useAuth } from '../lib/authContext'

export function AccountPage() {
  const { user } = useAuth()
  const toast = useToast()
  const [current, setCurrent] = useState('')
  const [next, setNext] = useState('')
  const [confirm, setConfirm] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [busy, setBusy] = useState(false)

  async function submit(e: FormEvent) {
    e.preventDefault()
    const found: Record<string, string> = {}
    if (!current) found.current_password = 'Wajib diisi'
    if (next.length < 10) found.new_password = 'Minimal 10 karakter'
    if (next !== confirm) found.confirm = 'Tidak sama dengan password baru'
    setErrors(found)
    if (Object.keys(found).length) return

    setBusy(true)
    try {
      await request('/auth/password', { method: 'PUT', body: { current_password: current, new_password: next } })
      setCurrent('')
      setNext('')
      setConfirm('')
      toast('Password diganti')
    } catch (err) {
      if (err instanceof ApiError && Object.keys(err.fields).length) setErrors(err.fields)
      else toast(err instanceof Error ? err.message : 'Gagal mengganti password', 'error')
    } finally {
      setBusy(false)
    }
  }

  const field = (id: string, label: string, value: string, set: (v: string) => void, autoComplete: string) => (
    <div className="field" data-invalid={errors[id] ? true : undefined}>
      <label htmlFor={id} className="field-label">
        {label}
      </label>
      <input id={id} className="input" type="password" autoComplete={autoComplete} value={value} onChange={(e) => set(e.target.value)} aria-invalid={errors[id] ? true : undefined} />
      {errors[id] && <p className="field-error">{errors[id].charAt(0).toUpperCase() + errors[id].slice(1)}</p>}
    </div>
  )

  return (
    <div className="page page-narrow">
      <header className="page-head">
        <div>
          <div className="eyebrow">Akun</div>
          <h1>Ganti password</h1>
          <p className="page-desc">Masuk sebagai {user?.email}.</p>
        </div>
      </header>
      <form className="form-card resource-form" onSubmit={submit} noValidate>
        <div className="form-fields">
          {field('current_password', 'Password saat ini', current, setCurrent, 'current-password')}
          {field('new_password', 'Password baru (min. 10 karakter)', next, setNext, 'new-password')}
          {field('confirm', 'Ulangi password baru', confirm, setConfirm, 'new-password')}
        </div>
        <div className="form-actions">
          <button className="btn btn-primary" disabled={busy}>
            {busy && <span className="spinner" aria-hidden />}
            Ganti password
          </button>
        </div>
      </form>
    </div>
  )
}
