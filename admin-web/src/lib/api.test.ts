import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { ApiError, UNAUTHORIZED_EVENT, deleteUploadedFile, login, request, session } from './api'

function reply(status: number, body: unknown) {
  return vi.fn().mockResolvedValue(new Response(JSON.stringify(body), { status }))
}

describe('api client', () => {
  beforeEach(() => sessionStorage.clear())
  afterEach(() => vi.unstubAllGlobals())

  it('unwraps data & meta and skips empty query params', async () => {
    const fetchMock = reply(200, { success: true, data: [{ id: '1' }], meta: { total: 1, limit: 50, offset: 0 } })
    vi.stubGlobal('fetch', fetchMock)

    const res = await request('/admin/agenda', { query: { limit: 50, kategori: '', tahun: undefined } })

    expect(res.data).toEqual([{ id: '1' }])
    expect(res.meta?.total).toBe(1)
    const url = fetchMock.mock.calls[0][0] as URL
    expect(url.pathname).toBe('/api/v1/admin/agenda')
    expect(url.search).toBe('?limit=50')
  })

  it('stores the session on login and sends the bearer token afterwards', async () => {
    const expires = new Date(Date.now() + 3600_000).toISOString()
    vi.stubGlobal('fetch', reply(200, { success: true, data: { token: 'jwt', email: 'a@b.c', expires_at: expires } }))
    await login('a@b.c', 'secret')
    expect(session.get()?.token).toBe('jwt')

    const fetchMock = reply(200, { success: true, data: [] })
    vi.stubGlobal('fetch', fetchMock)
    await request('/admin/faq')
    expect((fetchMock.mock.calls[0][1] as RequestInit).headers).toMatchObject({ Authorization: 'Bearer jwt' })
  })

  it('drops an expired session', () => {
    sessionStorage.setItem('gkjw-admin-session', JSON.stringify({ token: 'old', email: 'a', expires_at: '2000-01-01T00:00:00Z' }))
    expect(session.get()).toBeNull()
  })

  it('maps validation errors with fields', async () => {
    vi.stubGlobal('fetch', reply(400, { success: false, data: null, error: { code: 'validation_error', message: 'Data tidak valid', fields: { judul: 'wajib diisi' } } }))
    const err = await request('/admin/agenda', { method: 'POST', body: {} }).catch((e) => e)
    expect(err).toBeInstanceOf(ApiError)
    expect(err.fields.judul).toBe('wajib diisi')
  })

  it('clears the session and notifies the app on 401', async () => {
    session.set({ token: 'jwt', email: 'a', expires_at: new Date(Date.now() + 3600_000).toISOString() })
    const listener = vi.fn()
    window.addEventListener(UNAUTHORIZED_EVENT, listener)
    vi.stubGlobal('fetch', reply(401, { success: false, error: { code: 'unauthorized', message: 'Silakan login' } }))

    await expect(request('/admin/faq')).rejects.toBeInstanceOf(ApiError)
    expect(session.get()).toBeNull()
    expect(listener).toHaveBeenCalledOnce()
    window.removeEventListener(UNAUTHORIZED_EVENT, listener)
  })

  it('reports offline errors in plain language', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('Failed to fetch')))
    const err = await request('/admin/faq').catch((e) => e)
    expect(err.code).toBe('offline')
  })

  it('deletes only files hosted on our server', async () => {
    const fetchMock = reply(200, { success: true, data: {} })
    vi.stubGlobal('fetch', fetchMock)

    await deleteUploadedFile('https://drive.google.com/file/d/abc/view')
    await deleteUploadedFile(null)
    await deleteUploadedFile(`${window.location.origin}/files/galeri/0123456789abcdef0123456789abcdef.jpg`)

    expect(fetchMock).toHaveBeenCalledOnce()
    const [url, init] = fetchMock.mock.calls[0]
    expect((url as URL).pathname).toBe('/api/v1/admin/uploads/galeri/0123456789abcdef0123456789abcdef.jpg')
    expect((init as RequestInit).method).toBe('DELETE')
  })
})
