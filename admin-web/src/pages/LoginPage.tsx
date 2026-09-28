import { useState, type FormEvent } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { ApiError } from '../lib/api'
import { useAuth } from '../lib/authContext'

export function LoginPage() {
  const { user, login, expired } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const from = (location.state as { from?: string } | null)?.from ?? '/'
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  if (user) return <Navigate to={from} replace />

  async function submit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setBusy(true)
    try {
      await login(email.trim(), password)
      navigate(from, { replace: true })
    } catch (err) {
      if (err instanceof ApiError && err.status === 429) setError('Terlalu banyak percobaan. Tunggu 1 menit lalu coba lagi.')
      else if (err instanceof ApiError && err.code === 'unauthorized') setError('Email atau password salah.')
      else setError(err instanceof Error ? err.message : 'Login gagal.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="login">
      <div className="login-panel">
        <img src={`${import.meta.env.BASE_URL}logo.png`} alt="Logo GKJW Karangpilang" width={96} height={86} />
        <div className="eyebrow">Admin Jemaat</div>
        <h1>GKJW Karangpilang</h1>
        <p className="login-motto">“Patembayan Kang Nyawiji”</p>

        <form onSubmit={submit} className="login-form">
          {expired && !error && <p className="form-note">Sesi berakhir. Silakan masuk lagi.</p>}
          <div className="field">
            <label htmlFor="email" className="field-label">
              Email
            </label>
            <input id="email" className="input" type="email" autoComplete="username" required value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
          <div className="field">
            <label htmlFor="password" className="field-label">
              Password
            </label>
            <input id="password" className="input" type="password" autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} />
          </div>
          {error && (
            <p className="form-error" role="alert">
              {error}
            </p>
          )}
          <button className="btn btn-primary btn-block" disabled={busy}>
            {busy && <span className="spinner" aria-hidden />}
            Masuk
          </button>
        </form>
        <p className="login-foot">Hanya untuk pengurus. Akun dibuat oleh pengelola server.</p>
      </div>
    </div>
  )
}
