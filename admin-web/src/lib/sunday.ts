// "Persiapan Minggu": hitung Minggu terdekat dan periksa apakah konten mingguan sudah siap.

/** Minggu terdekat (hari ini bila hari ini Minggu), jam 00:00 waktu lokal. */
export function upcomingSunday(now: Date = new Date()): Date {
  const d = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  d.setDate(d.getDate() + ((7 - d.getDay()) % 7))
  return d
}

export function daysUntil(target: Date, now: Date = new Date()): number {
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  return Math.round((target.getTime() - today.getTime()) / 86_400_000)
}

/** Sama hari kalender (waktu lokal). */
export function isSameDay(iso: string | undefined | null, day: Date): boolean {
  if (!iso) return false
  const d = new Date(iso)
  return d.getFullYear() === day.getFullYear() && d.getMonth() === day.getMonth() && d.getDate() === day.getDate()
}

/** Tanggal input (YYYY-MM-DD) untuk mengisi otomatis form "Unggah untuk Minggu ini". */
export function toDateParam(day: Date): string {
  const p = (n: number) => String(n).padStart(2, '0')
  return `${day.getFullYear()}-${p(day.getMonth() + 1)}-${p(day.getDate())}`
}

export function countdownLabel(days: number): string {
  if (days === 0) return 'Hari ini'
  if (days === 1) return 'Besok'
  return `${days} hari lagi`
}
