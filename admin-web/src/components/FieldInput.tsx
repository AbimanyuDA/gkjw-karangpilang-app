import type { FormValue } from '../lib/form'
import { optionLabel } from '../lib/format'
import type { BucketSchema, FieldSchema } from '../lib/schema'
import { UploadField } from './UploadField'
import { YouTubeField } from './YouTubeField'

interface Props {
  field: FieldSchema
  value: FormValue
  error?: string
  buckets: Record<string, BucketSchema>
  disabled?: boolean
  onChange: (value: FormValue) => void
  onFill: (values: Record<string, string>) => void
  onBusyChange: (busy: boolean) => void
}

/** Satu baris form: label, kontrol sesuai jenis input dari skema, bantuan, dan pesan galat. */
export function FieldInput({ field, value, error, buckets, disabled, onChange, onFill, onBusyChange }: Props) {
  const id = `f-${field.name}`
  const str = typeof value === 'string' ? value : ''
  const describedBy = [field.help ? `${id}-help` : '', error ? `${id}-err` : ''].filter(Boolean).join(' ') || undefined
  const common = { id, 'aria-invalid': error ? true : undefined, 'aria-describedby': describedBy, disabled }

  let control
  switch (field.input) {
    case 'switch':
      control = (
        <label className="switch">
          <input {...common} type="checkbox" checked={Boolean(value)} onChange={(e) => onChange(e.target.checked)} />
          <span className="switch-track" aria-hidden />
          <span>{value ? 'Ya' : 'Tidak'}</span>
        </label>
      )
      break
    case 'textarea':
      control = (
        <textarea {...common} className="input textarea" value={str} rows={field.name === 'deskripsi' || field.name === 'jawaban' ? 5 : 3} maxLength={field.max_length} onChange={(e) => onChange(e.target.value)} />
      )
      break
    case 'select':
      control = (
        <select {...common} className="input" value={str} onChange={(e) => onChange(e.target.value)}>
          <option value="" disabled>
            Pilih…
          </option>
          {field.options?.map((o) => (
            <option key={o} value={o}>
              {optionLabel(o)}
            </option>
          ))}
        </select>
      )
      break
    case 'number':
      control = <input {...common} className="input input-narrow" type="number" inputMode="numeric" min={field.min} max={field.max} value={str} onChange={(e) => onChange(e.target.value)} />
      break
    case 'date':
      control = <input {...common} className="input input-narrow" type="date" value={str} onChange={(e) => onChange(e.target.value)} />
      break
    case 'datetime':
      control = <input {...common} className="input input-narrow" type="datetime-local" value={str} onChange={(e) => onChange(e.target.value)} />
      break
    case 'color':
      control = (
        <div className="color-field">
          <input {...common} type="color" value={str || '#1c3a63'} onChange={(e) => onChange(e.target.value.toUpperCase())} />
          <code>{str}</code>
        </div>
      )
      break
    case 'image':
    case 'pdf':
      control = (
        <UploadField field={field} bucket={field.upload ? buckets[field.upload] : undefined} value={str} onChange={onChange} onBusyChange={onBusyChange} />
      )
      break
    case 'youtube':
      control = <YouTubeField id={id} value={str} onChange={onChange} onFetched={onFill} />
      break
    default:
      control = (
        <input {...common} className="input" type={field.input === 'url' ? 'url' : 'text'} value={str} maxLength={field.max_length} onChange={(e) => onChange(e.target.value)} />
      )
  }

  return (
    <div className="field" data-invalid={error ? true : undefined}>
      <label htmlFor={id} className="field-label">
        {field.label}
        {field.required && <span className="field-required" aria-label="wajib"> *</span>}
      </label>
      {control}
      {field.help && field.input !== 'youtube' && (
        <p id={`${id}-help`} className="field-help">
          {field.help}
        </p>
      )}
      {error && (
        <p id={`${id}-err`} className="field-error">
          {error}
        </p>
      )}
    </div>
  )
}
