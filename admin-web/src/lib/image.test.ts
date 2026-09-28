import { describe, expect, it, vi } from 'vitest'
import { encodeImage, type Encoder } from './image'

const blob = (type: string) => new Blob(['x'], { type })

describe('encodeImage', () => {
  it('memakai WebP bila browser mendukung', async () => {
    const encode = vi.fn<Encoder>(async (type) => blob(type))
    const out = await encodeImage(encode, false)
    expect(out.type).toBe('image/webp')
    expect(encode).toHaveBeenCalledTimes(1)
    expect(encode).toHaveBeenCalledWith('image/webp', 0.82)
  })

  it('jatuh ke JPEG bila browser mengembalikan PNG untuk permintaan WebP', async () => {
    const encode = vi.fn<Encoder>(async (type) => blob(type === 'image/webp' ? 'image/png' : type))
    expect((await encodeImage(encode, false)).type).toBe('image/jpeg')
  })

  it('gambar transparan jatuh ke PNG agar latarnya tidak jadi hitam', async () => {
    const encode = vi.fn<Encoder>(async (type) => (type === 'image/webp' ? null : blob(type)))
    expect((await encodeImage(encode, true)).type).toBe('image/png')
  })

  it('error bila tidak ada format yang berhasil', async () => {
    await expect(encodeImage(async () => null, false)).rejects.toThrow('Gagal memproses gambar.')
  })
})
