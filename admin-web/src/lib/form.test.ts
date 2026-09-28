import { describe, expect, it } from 'vitest'
import { emptyValues, fromDateInput, toDateInput, toFormValues, toPayload, validate } from './form'
import type { FieldSchema } from './schema'

const f = (over: Partial<FieldSchema> & Pick<FieldSchema, 'name' | 'type'>): FieldSchema => ({
  label: over.name,
  input: 'text',
  required: false,
  nullable: true,
  ...over,
})

const fields: FieldSchema[] = [
  f({ name: 'judul', type: 'text', required: true, nullable: false, max_length: 10 }),
  f({ name: 'deskripsi', type: 'text', input: 'textarea' }),
  f({ name: 'urutan', type: 'int', nullable: false, min: 0, max: 5, input: 'number' }),
  f({ name: 'is_active', type: 'bool', nullable: false, input: 'switch' }),
  f({ name: 'tanggal', type: 'timestamp', required: true, nullable: false, input: 'date' }),
  f({ name: 'waktu', type: 'timestamp', input: 'datetime' }),
  f({ name: 'foto_url', type: 'text', input: 'image', upload: 'galeri' }),
  f({ name: 'kategori', type: 'text', input: 'select', options: ['warta', 'renungan'] }),
  f({ name: 'warna', type: 'text', input: 'color', pattern: '^#[0-9A-Fa-f]{6}$', nullable: false }),
]

describe('date conversion', () => {
  it('round-trips a local date', () => {
    const iso = fromDateInput('2026-10-04')
    expect(toDateInput(iso, false)).toBe('2026-10-04')
  })
  it('round-trips a local date-time', () => {
    const iso = fromDateInput('2026-10-04T18:30')
    expect(toDateInput(iso, true)).toBe('2026-10-04T18:30')
  })
  it('returns empty for garbage', () => {
    expect(toDateInput('bukan tanggal', false)).toBe('')
  })
})

describe('emptyValues', () => {
  it('uses sensible defaults and presets', () => {
    const v = emptyValues(fields, { kategori: 'warta' })
    expect(v.is_active).toBe(true)
    expect(v.urutan).toBe('0')
    expect(v.kategori).toBe('warta')
    expect(v.warna).toMatch(/^#/)
  })
})

describe('toFormValues / toPayload', () => {
  const row = {
    id: 'x',
    judul: 'Warta',
    deskripsi: null,
    urutan: 3,
    is_active: false,
    tanggal: fromDateInput('2026-10-04'),
    waktu: null,
    foto_url: 'https://api/files/galeri/a.jpg',
    kategori: 'renungan',
    warna: '#112233',
  }

  it('maps API row to form values', () => {
    const v = toFormValues(fields, row)
    expect(v).toMatchObject({ judul: 'Warta', deskripsi: '', urutan: '3', is_active: false, tanggal: '2026-10-04', kategori: 'renungan' })
  })

  it('maps form values back to API payload', () => {
    const payload = toPayload(fields, toFormValues(fields, row))
    expect(payload.judul).toBe('Warta')
    expect(payload.deskripsi).toBeNull() // opsional & kosong → null (menghapus nilai lama)
    expect(payload.urutan).toBe(3)
    expect(payload.is_active).toBe(false)
    expect(payload.tanggal).toBe(row.tanggal)
    expect(payload.waktu).toBeNull()
  })

  it('omits empty required fields instead of sending null', () => {
    const payload = toPayload(fields, { ...emptyValues(fields), judul: '   ' })
    expect('judul' in payload).toBe(false)
  })

  it('keeps textarea whitespace but trims single-line text', () => {
    const payload = toPayload(fields, { ...emptyValues(fields), judul: '  Warta  ', deskripsi: 'baris 1\n  baris 2' })
    expect(payload.judul).toBe('Warta')
    expect(payload.deskripsi).toBe('baris 1\n  baris 2')
  })
})

describe('validate', () => {
  const valid = {
    ...emptyValues(fields),
    judul: 'Warta',
    tanggal: '2026-10-04',
    kategori: 'warta',
    foto_url: 'https://x/a.jpg',
  }

  it('accepts valid values', () => {
    expect(validate(fields, valid)).toEqual({})
  })

  it.each([
    ['judul', '', 'Wajib diisi'],
    ['judul', 'x'.repeat(11), 'Maksimal 10 karakter'],
    ['urutan', 'abc', 'Harus berupa angka bulat'],
    ['urutan', '9', 'Maksimal 5'],
    ['urutan', '-1', 'Minimal 0'],
    ['foto_url', 'javascript:alert(1)', 'Unggah file terlebih dahulu'],
    ['kategori', 'lain', 'Pilih salah satu opsi'],
    ['warna', 'merah', 'Format tidak valid'],
    ['tanggal', '', 'Wajib diisi'],
  ])('%s = %j → %s', (name, value, message) => {
    expect(validate(fields, { ...valid, [name]: value })[name]).toBe(message)
  })
})
