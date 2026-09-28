import { useState } from 'react'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import {
  BookOpen,
  CalendarCheck,
  Church,
  Info,
  KeyRound,
  LogOut,
  Menu,
  Monitor,
  Moon,
  Sun,
  Users,
  X,
  type LucideIcon,
} from 'lucide-react'
import { useAuth } from '../lib/authContext'
import { useSchema } from '../lib/queries'
import { groupResources } from '../lib/schema'
import { useTheme, type ThemeMode } from '../lib/theme'

const GROUP_ICONS: Record<string, LucideIcon> = {
  Ibadah: BookOpen,
  Jemaat: Users,
  'Profil Gereja': Church,
  'Informasi & Pengaturan': Info,
}

const THEMES: { mode: ThemeMode; label: string; icon: LucideIcon }[] = [
  { mode: 'system', label: 'Ikuti sistem', icon: Monitor },
  { mode: 'light', label: 'Terang', icon: Sun },
  { mode: 'dark', label: 'Gelap', icon: Moon },
]

export function Shell() {
  const { user, logout } = useAuth()
  const { data: schema, isError } = useSchema()
  const [theme, setTheme] = useTheme()
  const location = useLocation()
  // Menu mobile tercatat terbuka untuk path tertentu → otomatis tertutup setelah berpindah halaman.
  const [openAt, setOpenAt] = useState<string | null>(null)
  const open = openAt === location.pathname
  const setOpen = (v: boolean) => setOpenAt(v ? location.pathname : null)

  return (
    <div className="shell" data-menu-open={open || undefined}>
      <header className="topbar">
        <button className="btn btn-ghost btn-icon" onClick={() => setOpen(true)} aria-label="Buka menu">
          <Menu size={20} />
        </button>
        <img src={`${import.meta.env.BASE_URL}logo.png`} alt="" width={32} height={29} />
        <span className="topbar-title">Admin GKJW</span>
      </header>

      <aside className="sidebar" aria-label="Menu admin">
        <div className="sidebar-head">
          <img src={`${import.meta.env.BASE_URL}logo.png`} alt="Logo GKJW Karangpilang" width={52} height={47} />
          <div>
            <div className="brand-name">GKJW</div>
            <div className="brand-sub">Karangpilang</div>
          </div>
          <button className="btn btn-ghost btn-icon sidebar-close" onClick={() => setOpen(false)} aria-label="Tutup menu">
            <X size={20} />
          </button>
        </div>

        <nav className="sidebar-nav">
          <NavLink to="/" end className="nav-item nav-home">
            <CalendarCheck size={18} aria-hidden />
            Persiapan Minggu
          </NavLink>

          {isError && <p className="nav-error">Menu gagal dimuat. Muat ulang halaman.</p>}
          {schema &&
            groupResources(schema.resources).map(([group, resources]) => {
              const Icon = GROUP_ICONS[group] ?? Info
              return (
                <section key={group} className="nav-group">
                  <h2 className="nav-group-title">
                    <Icon size={14} aria-hidden />
                    {group}
                  </h2>
                  {resources.map((r) => (
                    <NavLink key={r.path} to={`/k/${r.path}`} className="nav-item">
                      {r.label}
                    </NavLink>
                  ))}
                </section>
              )
            })}
        </nav>

        <div className="sidebar-foot">
          <div className="theme-picker" role="radiogroup" aria-label="Tampilan">
            {THEMES.map(({ mode, label, icon: Icon }) => (
              <button
                key={mode}
                role="radio"
                aria-checked={theme === mode}
                className="theme-option"
                onClick={() => setTheme(mode)}
                title={label}
              >
                <Icon size={15} aria-hidden />
                <span className="visually-hidden">{label}</span>
              </button>
            ))}
          </div>
          <div className="account">
            <NavLink to="/akun" className="account-email" title="Akun & password">
              <KeyRound size={14} aria-hidden />
              <span>{user?.email}</span>
            </NavLink>
            <button className="btn btn-ghost btn-icon" onClick={logout} aria-label="Keluar" title="Keluar">
              <LogOut size={17} />
            </button>
          </div>
        </div>
      </aside>
      <div className="scrim" onClick={() => setOpen(false)} aria-hidden />

      <main className="main" id="main">
        <Outlet />
      </main>
    </div>
  )
}
