import type { FieldSchema } from './schema'

export interface FieldGroup {
  /** Judul kelompok; kosong untuk field tanpa section. */
  title: string
  fields: FieldSchema[]
}

/** Kelompokkan field berurutan yang punya section sama, dengan urutan asli dipertahankan. */
export function groupBySection(fields: readonly FieldSchema[]): FieldGroup[] {
  return fields.reduce<FieldGroup[]>((groups, field) => {
    const title = field.section ?? ''
    const last = groups.at(-1)
    if (last && last.title === title) return [...groups.slice(0, -1), { title, fields: [...last.fields, field] }]
    return [...groups, { title, fields: [field] }]
  }, [])
}
