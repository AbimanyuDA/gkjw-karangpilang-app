import { useState, type FormEvent } from 'react'
import { ApiError } from '../lib/api'
import { emptyValues, toFormValues, toPayload, validate, type FormErrors, type FormValue, type FormValues } from '../lib/form'
import { useSave } from '../lib/queries'
import type { BucketSchema, ResourceSchema, Row } from '../lib/schema'
import { FieldInput } from './FieldInput'
import { useToast } from '../lib/toast'

interface Props {
  resource: ResourceSchema
  buckets: Record<string, BucketSchema>
  row?: Row | null
  /** Nilai awal untuk data baru, mis. dari tombol "Unggah warta Minggu ini". */
  preset?: Record<string, string>
  onSaved?: (row: Row) => void
  onCancel?: () => void
}

export function ResourceForm({ resource, buckets, row, preset, onSaved, onCancel }: Props) {
  const isNew = !row && !resource.singleton
  // Urutan diatur dengan drag di daftar; data baru otomatis ditaruh paling akhir oleh server.
  const fields = resource.sortable ? resource.fields.filter((f) => f.name !== 'urutan') : resource.fields
  const [values, setValues] = useState<FormValues>(() => (row ? toFormValues(fields, row) : emptyValues(fields, preset)))
  const [errors, setErrors] = useState<FormErrors>({})
  const [formError, setFormError] = useState<string | null>(null)
  const [uploading, setUploading] = useState(0)
  const save = useSave(resource)
  const toast = useToast()

  const set = (name: string, v: FormValue) => {
    setValues((prev) => ({ ...prev, [name]: v }))
    setErrors((prev) => {
      if (!prev[name]) return prev
      const { [name]: _removed, ...rest } = prev
      return rest
    })
  }

  // Isi otomatis dari YouTube: jangan timpa isian yang sudah diketik admin.
  const fill = (auto: Record<string, string>) =>
    setValues((prev) => {
      const next = { ...prev }
      for (const [k, v] of Object.entries(auto)) if (k in next && (!next[k] || k === 'tanggal')) next[k] = v
      return next
    })

  async function submit(e: FormEvent) {
    e.preventDefault()
    setFormError(null)
    const found = validate(fields, values)
    setErrors(found)
    if (Object.keys(found).length > 0) {
      document.getElementById(`f-${Object.keys(found)[0]}`)?.focus()
      return
    }
    try {
      const saved = await save.mutateAsync({ id: row?.id, body: toPayload(fields, values) })
      toast(isNew ? `${resource.label}: data ditambahkan` : 'Perubahan disimpan')
      onSaved?.(saved)
    } catch (err) {
      if (err instanceof ApiError && Object.keys(err.fields).length > 0) {
        setErrors(Object.fromEntries(Object.entries(err.fields).map(([k, v]) => [k, v.charAt(0).toUpperCase() + v.slice(1)])))
      } else {
        setFormError(err instanceof Error ? err.message : 'Gagal menyimpan.')
      }
    }
  }

  const busy = save.isPending || uploading > 0
  return (
    <form className="resource-form" onSubmit={submit} noValidate>
      <div className="form-fields">
        {fields.map((field) => (
          <FieldInput
            key={field.name}
            field={field}
            value={values[field.name]}
            error={errors[field.name]}
            buckets={buckets}
            disabled={save.isPending}
            onChange={(v) => set(field.name, v)}
            onFill={fill}
            onBusyChange={(b) => setUploading((n) => Math.max(0, n + (b ? 1 : -1)))}
          />
        ))}
      </div>
      {formError && (
        <p className="form-error" role="alert">
          {formError}
        </p>
      )}
      <div className="form-actions">
        {onCancel && (
          <button type="button" className="btn btn-secondary" onClick={onCancel} disabled={save.isPending}>
            Batal
          </button>
        )}
        <button type="submit" className="btn btn-primary" disabled={busy}>
          {save.isPending && <span className="spinner" aria-hidden />}
          {uploading > 0 ? 'Menunggu upload…' : isNew ? 'Tambahkan' : 'Simpan perubahan'}
        </button>
      </div>
    </form>
  )
}
