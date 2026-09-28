import { useId, useRef, useState } from 'react'
import { FileText, ImagePlus, Trash2, Upload } from 'lucide-react'
import { ApiError, upload } from '../lib/api'
import { formatBytes } from '../lib/format'
import { compressImage } from '../lib/image'
import type { BucketSchema, FieldSchema } from '../lib/schema'

interface Props {
  field: FieldSchema
  bucket: BucketSchema | undefined
  value: string
  onChange: (url: string) => void
  /** Dilaporkan ke form agar tombol simpan menunggu upload selesai. */
  onBusyChange: (busy: boolean) => void
}

const ACCEPT = { image: 'image/jpeg,image/png,image/webp', pdf: 'application/pdf' }

export function UploadField({ field, bucket, value, onChange, onBusyChange }: Props) {
  const id = useId()
  const input = useRef<HTMLInputElement>(null)
  const [progress, setProgress] = useState<number | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [dragOver, setDragOver] = useState(false)
  const kind = field.input === 'pdf' ? 'pdf' : 'image'

  async function handle(file: File | undefined) {
    if (!file || !field.upload) return
    setError(null)
    const payload = kind === 'image' ? await compressImage(file) : file
    if (bucket && payload.size > bucket.max_bytes) {
      setError(`Ukuran file ${formatBytes(payload.size)} — maksimal ${formatBytes(bucket.max_bytes)}.`)
      return
    }
    setProgress(0)
    onBusyChange(true)
    try {
      const uploaded = await upload(field.upload, payload, setProgress)
      onChange(uploaded.url)
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'Upload gagal. Coba lagi.')
    } finally {
      setProgress(null)
      onBusyChange(false)
      if (input.current) input.current.value = ''
    }
  }

  const busy = progress !== null
  return (
    <div className={`upload upload-${kind}`}>
      {value ? (
        <div className="upload-preview">
          {kind === 'image' ? (
            <img src={value} alt={`Pratinjau ${field.label.toLowerCase()}`} />
          ) : (
            <a href={value} target="_blank" rel="noreferrer" className="upload-file">
              <FileText size={22} aria-hidden />
              <span>Dokumen PDF terunggah</span>
              <span className="upload-open">Buka ↗</span>
            </a>
          )}
          <div className="upload-actions">
            <button type="button" className="btn btn-secondary" onClick={() => input.current?.click()} disabled={busy}>
              <Upload size={15} aria-hidden /> Ganti
            </button>
            {!field.required && (
              <button type="button" className="btn btn-ghost" onClick={() => onChange('')} disabled={busy}>
                <Trash2 size={15} aria-hidden /> Kosongkan
              </button>
            )}
          </div>
        </div>
      ) : (
        <label
          htmlFor={id}
          className="upload-drop"
          data-drag={dragOver || undefined}
          onDragOver={(e) => {
            e.preventDefault()
            setDragOver(true)
          }}
          onDragLeave={() => setDragOver(false)}
          onDrop={(e) => {
            e.preventDefault()
            setDragOver(false)
            handle(e.dataTransfer.files[0])
          }}
        >
          {kind === 'image' ? <ImagePlus size={26} aria-hidden /> : <FileText size={26} aria-hidden />}
          <span className="upload-cta">{kind === 'image' ? 'Pilih gambar' : 'Pilih file PDF'}</span>
          <span className="upload-hint">
            atau seret ke sini · {kind === 'image' ? 'JPG, PNG, WebP' : 'PDF'}
            {bucket ? ` · maks. ${formatBytes(bucket.max_bytes)}` : ''}
          </span>
        </label>
      )}

      <input
        ref={input}
        id={id}
        type="file"
        accept={ACCEPT[kind]}
        className="visually-hidden"
        onChange={(e) => handle(e.target.files?.[0])}
      />

      {busy && (
        <div className="upload-progress" role="progressbar" aria-valuenow={Math.round((progress ?? 0) * 100)} aria-valuemin={0} aria-valuemax={100}>
          <div style={{ transform: `scaleX(${progress ?? 0})` }} />
          <span>Mengunggah… {Math.round((progress ?? 0) * 100)}%</span>
        </div>
      )}
      {error && <p className="field-error">{error}</p>}
    </div>
  )
}
