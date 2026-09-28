import { describe, expect, it } from 'vitest'
import type { FieldSchema } from './schema'
import { groupBySection } from './sections'

const f = (name: string, section?: string) => ({ name, section }) as FieldSchema

describe('groupBySection', () => {
  it('mengelompokkan field berurutan dengan section sama', () => {
    const groups = groupBySection([f('nama', 'Umum'), f('alamat', 'Umum'), f('foto', 'Sejarah'), f('sejarah', 'Sejarah')])
    expect(groups.map((g) => [g.title, g.fields.map((x) => x.name)])).toEqual([
      ['Umum', ['nama', 'alamat']],
      ['Sejarah', ['foto', 'sejarah']],
    ])
  })

  it('field tanpa section menjadi satu kelompok tanpa judul', () => {
    expect(groupBySection([f('a'), f('b')])).toEqual([{ title: '', fields: [f('a'), f('b')] }])
  })

  it('daftar kosong', () => {
    expect(groupBySection([])).toEqual([])
  })
})
