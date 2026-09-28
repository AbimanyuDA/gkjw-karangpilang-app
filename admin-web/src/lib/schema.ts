// Bentuk skema dari GET /api/v1/admin/schema (sumber: backend/internal/resource/registry.go).

export type FieldType = 'text' | 'int' | 'bool' | 'timestamp'

export type InputKind =
  | 'text'
  | 'textarea'
  | 'url'
  | 'image'
  | 'pdf'
  | 'color'
  | 'select'
  | 'number'
  | 'switch'
  | 'datetime'
  | 'date'
  | 'youtube'

/** Panduan ukuran gambar sesuai tampilan di aplikasi. */
export interface ImageSpec {
  aspect_w: number
  aspect_h: number
  width: number
  height: number
  min_width: number
  min_height: number
  note?: string
  /** Wajib dipotong ke rasio ini sebelum diunggah. */
  crop: boolean
  /** Ditampilkan dalam lingkaran di aplikasi. */
  round: boolean
}

export interface FieldSchema {
  name: string
  label: string
  help?: string
  type: FieldType
  input: InputKind
  required: boolean
  nullable: boolean
  max_length?: number
  options?: string[]
  min?: number
  max?: number
  pattern?: string
  upload?: string
  image?: ImageSpec
  /** Judul kelompok di form; field berurutan dengan section sama tampil bersama. */
  section?: string
}

export interface ResourceSchema {
  path: string
  label: string
  group: string
  description?: string
  singleton: boolean
  /** Punya kolom "urutan": diurutkan dengan drag di daftar. */
  sortable: boolean
  upsert_key?: string
  title_field?: string
  columns: string[]
  filters: string[]
  fields: FieldSchema[]
}

export interface BucketSchema {
  kind: 'image' | 'pdf'
  max_bytes: number
}

export interface AdminSchema {
  resources: ResourceSchema[]
  buckets: Record<string, BucketSchema>
}

/** Satu baris data dari API (kolom → nilai JSON). */
export type Row = Record<string, unknown> & { id: string; created_at?: string; updated_at?: string }

export function fieldOf(resource: ResourceSchema, name: string): FieldSchema | undefined {
  return resource.fields.find((f) => f.name === name)
}

/** Kelompokkan resource per menu, mempertahankan urutan dari server. */
export function groupResources(resources: ResourceSchema[]): [string, ResourceSchema[]][] {
  const groups = new Map<string, ResourceSchema[]>()
  for (const r of resources) {
    const list = groups.get(r.group) ?? []
    list.push(r)
    groups.set(r.group, list)
  }
  return [...groups.entries()]
}
