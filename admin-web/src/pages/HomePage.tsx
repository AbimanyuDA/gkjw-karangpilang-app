import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { ArrowRight, BellRing, CalendarDays, Check, Megaphone } from 'lucide-react'
import { request } from '../lib/api'
import { formatDate, formatLongDay } from '../lib/format'
import type { Row } from '../lib/schema'
import { countdownLabel, daysUntil, isSameDay, toDateParam, upcomingSunday } from '../lib/sunday'

interface Task {
  key: string
  label: string
  /** Keterangan bila belum siap. */
  hint: string
  resource: string
  kategori: string
  afterService?: boolean
}

// Tugas mingguan pengurus: yang dibuka jemaat sebelum & sesudah ibadah Minggu.
const TASKS: Task[] = [
  { key: 'warta', label: 'Warta Jemaat', hint: 'Jemaat membaca warta sebelum ibadah.', resource: 'dokumen', kategori: 'warta' },
  { key: 'tata_ibadah', label: 'Tata Ibadah', hint: 'Dibuka jemaat selama ibadah berlangsung.', resource: 'dokumen', kategori: 'tata_ibadah' },
  { key: 'siaran', label: 'Video ibadah umum', hint: 'Biasanya diunggah setelah ibadah selesai.', resource: 'siaran', kategori: 'umum', afterService: true },
]

async function fetchRecent(resource: string, kategori: string): Promise<Row[]> {
  return (await request<Row[]>(`/admin/${resource}`, { query: { kategori, limit: 10 } })).data
}

export function HomePage() {
  const sunday = upcomingSunday()
  const days = daysUntil(sunday)

  const tasks = useQuery({
    queryKey: ['sunday', toDateParam(sunday)],
    queryFn: async () => {
      const results = await Promise.all(TASKS.map((t) => fetchRecent(t.resource, t.kategori)))
      return TASKS.map((t, i) => ({ task: t, match: results[i].find((r) => isSameDay(r.tanggal as string, sunday)) }))
    },
  })
  const pengumuman = useQuery({
    queryKey: ['list', 'notifikasi', 'aktif'],
    queryFn: async () => (await request<Row[]>('/admin/notifikasi', { query: { limit: 200 } })).data.filter((r) => r.is_active),
  })
  const agenda = useQuery({
    queryKey: ['list', 'agenda', 'minggu-ini'],
    queryFn: async () => {
      const now = Date.now()
      const week = now + 7 * 86_400_000
      return (await request<Row[]>('/admin/agenda', { query: { limit: 200 } })).data.filter((r) => {
        const t = new Date(r.tanggal as string).getTime()
        return t >= now - 86_400_000 && t <= week
      })
    },
  })

  const ready = tasks.data?.filter((t) => t.match).length ?? 0
  return (
    <div className="page home">
      <header className="sunday-hero">
        <div className="eyebrow">Persiapan Minggu</div>
        <h1>{formatLongDay(sunday)}</h1>
        <div className="sunday-meta">
          <span className="badge badge-accent">{countdownLabel(days)}</span>
          {tasks.data && (
            <span className="sunday-progress">
              {ready} dari {TASKS.length} siap untuk jemaat
            </span>
          )}
        </div>
      </header>

      <section className="checklist" aria-label="Daftar persiapan">
        {tasks.isLoading && <span className="spinner" aria-label="Memuat" />}
        {tasks.isError && <p className="form-error">Status gagal dimuat: {(tasks.error as Error).message}</p>}
        {tasks.data?.map(({ task, match }) => (
          <article key={task.key} className="check-row" data-ready={Boolean(match) || undefined}>
            <span className="check-mark" aria-hidden>
              {match && <Check size={16} strokeWidth={3} />}
            </span>
            <div className="check-body">
              <h2>{task.label}</h2>
              {match ? (
                <p>
                  <strong>{String(match.judul)}</strong> · {formatDate(match.tanggal as string)}
                </p>
              ) : (
                <p className="muted">{task.hint}</p>
              )}
            </div>
            {match ? (
              <Link className="btn btn-ghost" to={`/k/${task.resource}?ubah=${match.id}`}>
                Lihat
              </Link>
            ) : (
              <Link
                className={task.afterService ? 'btn btn-secondary' : 'btn btn-primary'}
                to={`/k/${task.resource}?${new URLSearchParams({ baru: '1', kategori: task.kategori, 'isi.kategori': task.kategori, 'isi.tanggal': toDateParam(sunday) })}`}
              >
                {task.resource === 'siaran' ? 'Tambah video' : `Unggah ${task.label.toLowerCase()}`}
                <ArrowRight size={16} aria-hidden />
              </Link>
            )}
          </article>
        ))}
      </section>

      <section className="glance" aria-label="Sekilas">
        <Link to="/k/notifikasi" className="glance-card">
          <Megaphone size={20} aria-hidden />
          <div>
            <strong>{pengumuman.data?.length ?? '–'}</strong>
            <span>pengumuman tampil di aplikasi</span>
          </div>
        </Link>
        <Link to="/k/agenda" className="glance-card">
          <CalendarDays size={20} aria-hidden />
          <div>
            <strong>{agenda.data?.length ?? '–'}</strong>
            <span>agenda dalam 7 hari ke depan</span>
          </div>
        </Link>
        <Link to="/k/sapaan-config" className="glance-card">
          <BellRing size={20} aria-hidden />
          <div>
            <strong>Sapaan</strong>
            <span>atur ayat pagi & malam</span>
          </div>
        </Link>
      </section>
    </div>
  )
}
