// Logika potong gambar (murni, mudah diuji) + render hasil potongan ke Blob.
import type { ImageSpec } from './schema'

export interface Area {
  x: number
  y: number
  width: number
  height: number
}

export function ratioLabel(spec: ImageSpec): string {
  return `${spec.aspect_w}:${spec.aspect_h}`
}

/** "Rasio 16:9 · ideal 1280 × 720 px · min. 800 × 450 px" */
export function specLabel(spec: ImageSpec): string {
  return `Rasio ${ratioLabel(spec)} · ideal ${spec.width} × ${spec.height} px · min. ${spec.min_width} × ${spec.min_height} px`
}

/**
 * Ukuran hasil: ukuran ideal, tapi tidak pernah memperbesar area yang lebih kecil
 * (memperbesar hanya membuat gambar buram & file lebih besar).
 */
export function outputSize(area: Area, spec: ImageSpec): { width: number; height: number } {
  const scale = Math.min(1, spec.width / area.width, spec.height / area.height)
  return { width: Math.round(area.width * scale), height: Math.round(area.height * scale) }
}

export type Quality = 'ok' | 'low'

/** "low" bila area yang dipilih lebih kecil dari ukuran minimum → tampak pecah di aplikasi. */
export function cropQuality(area: Area, spec: ImageSpec): Quality {
  return area.width < spec.min_width || area.height < spec.min_height ? 'low' : 'ok'
}

/** Peringatan untuk foto yang diunggah tanpa dipotong. */
export function uncroppedWarning(width: number, height: number, spec: ImageSpec): string | null {
  if (width < spec.min_width || height < spec.min_height)
    return `Foto ${width} × ${height} px lebih kecil dari minimum ${spec.min_width} × ${spec.min_height} px — bisa tampak pecah.`
  return null
}

export function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => resolve(img)
    img.onerror = () => reject(new Error('Gambar tidak bisa dibuka. Coba file JPG/PNG lain.'))
    img.src = src
  })
}

/** Gambar area terpilih ke kanvas seukuran hasil, lalu jadikan file. */
export async function renderCrop(src: string, area: Area, spec: ImageSpec, type: string): Promise<Blob> {
  const img = await loadImage(src)
  const size = outputSize(area, spec)
  const canvas = document.createElement('canvas')
  canvas.width = size.width
  canvas.height = size.height
  const ctx = canvas.getContext('2d')
  if (!ctx) throw new Error('Browser tidak mendukung pemotongan gambar.')
  ctx.imageSmoothingQuality = 'high'
  ctx.drawImage(img, area.x, area.y, area.width, area.height, 0, 0, size.width, size.height)
  const outType = type === 'image/png' ? 'image/png' : 'image/jpeg'
  const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, outType, 0.86))
  if (!blob) throw new Error('Gagal memproses gambar.')
  return blob
}
