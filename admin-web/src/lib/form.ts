// Konversi nilai antara API (JSON) ↔ form HTML, plus validasi di sisi browser
// yang mencerminkan aturan backend (backend tetap memvalidasi ulang).
import type { FieldSchema, Row } from './schema'

export type FormValue = string | boolean
export type FormValues = Record<string, FormValue>
export type FormErrors = Record<string, string>

const pad = (n: number) => String(n).padStart(2, '0')

/** Tanggal lokal (zona browser, WIB untuk pengurus gereja) dalam format input HTML. */
export function toDateInput(iso: string, withTime: boolean): string {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  const date = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
  return withTime ? `${date}T${pad(d.getHours())}:${pad(d.getMinutes())}` : date
}

/** Nilai input tanggal (waktu lokal) → ISO UTC untuk API. */
export function fromDateInput(value: string): string {
  const withTime = value.includes('T') ? value : `${value}T00:00`
  return new Date(withTime).toISOString()
}

export function emptyValues(fields: FieldSchema[], preset: Record<string, string> = {}): FormValues {
  const values: FormValues = {}
  for (const f of fields) {
    if (f.type === 'bool') values[f.name] = preset[f.name] ? preset[f.name] === 'true' : true
    else if (f.name === 'urutan') values[f.name] = preset[f.name] ?? '0'
    else if (f.input === 'color') values[f.name] = preset[f.name] ?? '#1C3A63'
    else values[f.name] = preset[f.name] ?? ''
  }
  return values
}

export function toFormValues(fields: FieldSchema[], row: Row | null | undefined): FormValues {
  const values = emptyValues(fields)
  if (!row) return values
  for (const f of fields) {
    const v = row[f.name]
    if (v === null || v === undefined) continue
    switch (f.type) {
      case 'bool':
        values[f.name] = Boolean(v)
        break
      case 'timestamp':
        values[f.name] = toDateInput(String(v), f.input === 'datetime')
        break
      default:
        values[f.name] = String(v)
    }
  }
  return values
}

/** Nilai form → body JSON. Teks kosong pada field opsional dikirim sebagai null. */
export function toPayload(fields: FieldSchema[], values: FormValues): Record<string, unknown> {
  const out: Record<string, unknown> = {}
  for (const f of fields) {
    const v = values[f.name]
    if (f.type === 'bool') {
      out[f.name] = Boolean(v)
      continue
    }
    const s = typeof v === 'string' ? v.trim() : ''
    if (s === '') {
      if (f.nullable) out[f.name] = null
      continue // wajib/NOT NULL yang kosong: biarkan validasi yang melapor
    }
    if (f.type === 'int') out[f.name] = Number(s)
    else if (f.type === 'timestamp') out[f.name] = fromDateInput(s)
    else out[f.name] = f.type === 'text' && f.input === 'textarea' ? String(v) : s
  }
  return out
}

export function validate(fields: FieldSchema[], values: FormValues): FormErrors {
  const errors: FormErrors = {}
  for (const f of fields) {
    if (f.type === 'bool') continue
    const s = String(values[f.name] ?? '').trim()
    if (s === '') {
      if (f.required || !f.nullable) errors[f.name] = 'Wajib diisi'
      continue
    }
    if (f.type === 'int') {
      if (!/^-?\d+$/.test(s)) errors[f.name] = 'Harus berupa angka bulat'
      else if (f.min !== undefined && Number(s) < f.min) errors[f.name] = `Minimal ${f.min}`
      else if (f.max !== undefined && Number(s) > f.max) errors[f.name] = `Maksimal ${f.max}`
      continue
    }
    if (f.max_length && s.length > f.max_length) errors[f.name] = `Maksimal ${f.max_length} karakter`
    else if ((f.input === 'url' || f.input === 'image' || f.input === 'pdf') && !/^https?:\/\//.test(s))
      errors[f.name] = f.input === 'url' ? 'Harus diawali http:// atau https://' : 'Unggah file terlebih dahulu'
    else if (f.pattern && !new RegExp(f.pattern).test(s)) errors[f.name] = 'Format tidak valid'
    else if (f.options && !f.options.includes(s)) errors[f.name] = 'Pilih salah satu opsi'
  }
  return errors
}
