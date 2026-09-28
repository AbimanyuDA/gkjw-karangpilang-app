// Kecilkan foto sebelum diunggah: HP pengurus sering menghasilkan foto 4–8 MB,
// padahal di aplikasi cukup ±1600 px. Hemat kuota jemaat & ruang server.

const MAX_SIDE = 1600
const SKIP_BELOW = 350 * 1024 // file kecil tidak perlu diproses

export async function compressImage(file: File): Promise<Blob> {
  if (file.size < SKIP_BELOW || !file.type.startsWith('image/') || file.type === 'image/gif') return file
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
    // PNG transparan (mis. logo) tetap PNG; foto menjadi JPEG.
    const type = file.type === 'image/png' ? 'image/png' : 'image/jpeg'
    const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, type, 0.82))
    return blob && blob.size < file.size ? blob : file
  } catch {
    return file // browser lama / format tidak didukung: unggah apa adanya
  }
}
