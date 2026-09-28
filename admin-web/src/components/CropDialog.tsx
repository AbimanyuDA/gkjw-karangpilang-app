import { useEffect, useRef, useState } from 'react'
import Cropper from 'react-easy-crop'
import { AlertTriangle, Minus, Plus, RotateCcw, X } from 'lucide-react'
import { cropQuality, outputSize, ratioLabel, renderCrop, type Area } from '../lib/crop'
import type { ImageSpec } from '../lib/schema'

interface Props {
  /** Alamat sementara foto (object URL) — dibuat & dihapus oleh pemanggil. */
  src: string
  /** Jenis file asli, menentukan format hasil (PNG tetap PNG). */
  fileType: string
  spec: ImageSpec
  label: string
  /** Hasil potongan siap diunggah. */
  onDone: (blob: Blob) => void
  /** Pakai foto apa adanya (hanya bila spec.crop = false, mis. galeri). */
  onUseOriginal: () => void
  onCancel: () => void
}

const MIN_ZOOM = 1
const MAX_ZOOM = 4

/** Potong & zoom gambar sesuai area yang tampil di aplikasi, sebelum diunggah. */
export function CropDialog({ src, fileType, spec, label, onDone, onUseOriginal, onCancel }: Props) {
  const ref = useRef<HTMLDialogElement>(null)
  const [crop, setCrop] = useState({ x: 0, y: 0 })
  const [zoom, setZoom] = useState(1)
  const [area, setArea] = useState<Area | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const d = ref.current
    if (d && !d.open) d.showModal()
    return () => d?.close()
  }, [])

  const setZoomClamped = (z: number) => setZoom(Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, Math.round(z * 10) / 10)))
  const out = area ? outputSize(area, spec) : null
  const lowQuality = area ? cropQuality(area, spec) === 'low' : false

  async function confirm() {
    if (!area) return
    setBusy(true)
    setError(null)
    try {
      onDone(await renderCrop(src, area, spec, fileType))
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Gagal memotong gambar.')
      setBusy(false)
    }
  }

  return (
    <dialog ref={ref} className="crop-dialog" aria-labelledby="crop-title" onCancel={(e) => (e.preventDefault(), onCancel())}>
      <header className="crop-head">
        <div>
          <div className="eyebrow">Sesuaikan {label.toLowerCase()}</div>
          <h2 id="crop-title">Area yang tampil di aplikasi</h2>
        </div>
        <button type="button" className="btn btn-ghost btn-icon" onClick={onCancel} aria-label="Batal">
          <X size={20} />
        </button>
      </header>

      <div className="crop-stage">
        <Cropper
          image={src}
          crop={crop}
          zoom={zoom}
          minZoom={MIN_ZOOM}
          maxZoom={MAX_ZOOM}
          aspect={spec.aspect_w / spec.aspect_h}
          cropShape={spec.round ? 'round' : 'rect'}
          showGrid
          objectFit="contain"
          onCropChange={setCrop}
          onZoomChange={setZoomClamped}
          onCropComplete={(_, pixels) => setArea(pixels)}
        />
      </div>

      <div className="crop-controls">
        <div className="zoom-row">
          <button type="button" className="btn btn-ghost btn-icon" onClick={() => setZoomClamped(zoom - 0.2)} aria-label="Perkecil" disabled={zoom <= MIN_ZOOM}>
            <Minus size={18} />
          </button>
          <input
            type="range"
            min={MIN_ZOOM}
            max={MAX_ZOOM}
            step={0.05}
            value={zoom}
            onChange={(e) => setZoom(Number(e.target.value))}
            aria-label="Zoom"
            className="zoom-slider"
          />
          <button type="button" className="btn btn-ghost btn-icon" onClick={() => setZoomClamped(zoom + 0.2)} aria-label="Perbesar" disabled={zoom >= MAX_ZOOM}>
            <Plus size={18} />
          </button>
          <span className="zoom-value">{zoom.toFixed(1)}×</span>
          <button type="button" className="btn btn-ghost" onClick={() => (setZoom(1), setCrop({ x: 0, y: 0 }))}>
            <RotateCcw size={15} aria-hidden /> Reset
          </button>
        </div>

        <dl className="crop-info">
          <div>
            <dt>Tampil di aplikasi</dt>
            <dd>
              Rasio {ratioLabel(spec)}
              {spec.round ? ' · lingkaran' : ''}
            </dd>
          </div>
          <div>
            <dt>Ukuran hasil</dt>
            <dd>{out ? `${out.width} × ${out.height} px` : '—'}</dd>
          </div>
          <div>
            <dt>Diambil dari foto asli</dt>
            <dd>{area ? `${Math.round(area.width)} × ${Math.round(area.height)} px` : '—'}</dd>
          </div>
          <div>
            <dt>Ideal</dt>
            <dd>
              {spec.width} × {spec.height} px
            </dd>
          </div>
        </dl>
        {spec.note && <p className="field-help">{spec.note}</p>}
        {lowQuality && (
          <p className="crop-warning" role="status">
            <AlertTriangle size={16} aria-hidden /> Area terlalu kecil (minimum {spec.min_width} × {spec.min_height} px) — gambar bisa tampak pecah. Perkecil zoom atau pakai foto beresolusi lebih besar.
          </p>
        )}
        {error && <p className="form-error">{error}</p>}
        <p className="crop-hint">Geser gambar untuk mengatur posisi, scroll atau slider untuk zoom.</p>
      </div>

      <footer className="form-actions crop-actions">
        <button type="button" className="btn btn-secondary" onClick={onCancel} disabled={busy}>
          Batal
        </button>
        {!spec.crop && (
          <button type="button" className="btn btn-secondary" onClick={onUseOriginal} disabled={busy}>
            Pakai foto utuh
          </button>
        )}
        <button type="button" className="btn btn-primary" onClick={confirm} disabled={!area || busy}>
          {busy && <span className="spinner" aria-hidden />}
          Potong & unggah
        </button>
      </footer>
    </dialog>
  )
}
