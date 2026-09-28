// Semua foto diubah ke WebP sebelum diunggah: ukurannya jauh lebih kecil dari JPEG/PNG
// pada kualitas yang sama, jadi hemat ruang server dan cepat dimuat di HP jemaat.
// Foto besar dari HP (4–8 MB) juga dikecilkan ke ±1600 px — cukup untuk layar HP.

const MAX_SIDE = 1600
export const WEBP_QUALITY = 0.82

/** Mengubah isi kanvas menjadi file dengan tipe & kualitas tertentu (null bila gagal). */
export type Encoder = (type: string, quality: number) => Promise<Blob | null>

export function canvasEncoder(canvas: HTMLCanvasElement): Encoder {
  return (type, quality) => new Promise((resolve) => canvas.toBlob(resolve, type, quality))
}

/**
 * Hasilkan WebP. Browser yang belum bisa membuat WebP (mis. Safari versi lama) diam-diam
 * mengembalikan PNG, jadi tipe hasilnya dicek: bila bukan WebP, pakai JPEG
 * (atau PNG untuk gambar transparan seperti logo).
 */
export async function encodeImage(encode: Encoder, transparent: boolean, quality = WEBP_QUALITY): Promise<Blob> {
  const webp = await encode('image/webp', quality)
  if (webp?.type === 'image/webp') return webp
  const fallback = await encode(transparent ? 'image/png' : 'image/jpeg', quality)
  if (!fallback) throw new Error('Gagal memproses gambar.')
  return fallback
}

/** Foto tanpa dipotong ("pakai foto utuh"): kecilkan bila perlu, lalu jadikan WebP. */
export async function compressImage(file: File): Promise<Blob> {
  if (!file.type.startsWith('image/') || file.type === 'image/gif') return file
  try {
    const bitmap = await createImageBitmap(file)
    const scale = Math.min(1, MAX_SIDE / Math.max(bitmap.width, bitmap.height))
    const canvas = document.createElement('canvas')
    canvas.width = Math.round(bitmap.width * scale)
    canvas.height = Math.round(bitmap.height * scale)
    const ctx = canvas.getContext('2d')
    if (!ctx) return file
    ctx.drawImage(bitmap, 0, 0, canvas.width, canvas.height)
    bitmap.close()
    const out = await encodeImage(canvasEncoder(canvas), file.type === 'image/png')
    // File asli yang sudah WebP dan lebih kecil tidak perlu diganti.
    return file.type === 'image/webp' && file.size <= out.size ? file : out
  } catch {
    return file // browser lama / format tidak didukung: unggah apa adanya
  }
}
