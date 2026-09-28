// Label & format tampilan (bahasa Indonesia).

const OPTION_LABELS: Record<string, string> = {
  warta: 'Warta Jemaat',
  tata_ibadah: 'Tata Ibadah',
  renungan: 'Renungan',
  umum: 'Ibadah Umum',
  anak: 'Anak',
  remaja: 'Remaja',
  sekolah_minggu: 'Sekolah Minggu',
  dewasa: 'Dewasa',
  informasi_gereja: 'Informasi Gereja',
  kependetaan: 'Kependetaan',
  kemajelisan: 'Kemajelisan',
  bpm: 'Badan Pembantu Majelis',
  perwilayahan: 'Perwilayahan',
  profil_ruangan: 'Profil Ruangan',
  whatsapp: 'WhatsApp',
  email: 'Email',
  instagram: 'Instagram',
  facebook: 'Facebook',
  youtube: 'YouTube',
}

export function optionLabel(value: string): string {
  return OPTION_LABELS[value] ?? value.replace(/_/g, ' ').replace(/^\w/, (c) => c.toUpperCase())
}

const dateFmt = new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })
const dateTimeFmt = new Intl.DateTimeFormat('id-ID', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
})
const longDayFmt = new Intl.DateTimeFormat('id-ID', { weekday: 'long', day: 'numeric', month: 'long' })

export function formatDate(iso: string, withTime = false): string {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return '—'
  return (withTime ? dateTimeFmt : dateFmt).format(d)
}

export function formatLongDay(d: Date): string {
  return longDayFmt.format(d)
}

export function formatBytes(n: number): string {
  if (n < 1024) return `${n} B`
  if (n < 1024 * 1024) return `${Math.round(n / 1024)} KB`
  return `${(n / 1024 / 1024).toFixed(1)} MB`
}
