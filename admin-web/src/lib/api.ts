// Klien API admin. Semua respons berbentuk { success, data, error, meta }.

export interface Meta {
  total: number
  limit: number
  offset: number
}

export interface Session {
  token: string
  email: string
  expires_at: string
}

export class ApiError extends Error {
  readonly code: string
  readonly fields: Record<string, string>
  readonly status: number

  constructor(message: string, code: string, status: number, fields: Record<string, string> = {}) {
    super(message)
    this.name = 'ApiError'
    this.code = code
    this.status = status
    this.fields = fields
  }
}

const SESSION_KEY = 'gkjw-admin-session'
export const UNAUTHORIZED_EVENT = 'gkjw:unauthorized'

// Sesi disimpan di sessionStorage: hilang saat tab ditutup (lebih aman di komputer bersama).
export const session = {
  get(): Session | null {
    try {
      const raw = sessionStorage.getItem(SESSION_KEY)
      if (!raw) return null
      const s = JSON.parse(raw) as Session
      if (!s.token || new Date(s.expires_at).getTime() <= Date.now()) {
        sessionStorage.removeItem(SESSION_KEY)
        return null
      }
      return s
    } catch {
      return null
    }
  },
  set(s: Session) {
    try {
      sessionStorage.setItem(SESSION_KEY, JSON.stringify(s))
    } catch {
      // penyimpanan diblokir browser: sesi hanya bertahan di memori tab ini
    }
    memorySession = s
  },
  clear() {
    memorySession = null
    try {
      sessionStorage.removeItem(SESSION_KEY)
    } catch {
      /* diabaikan */
    }
  },
}
let memorySession: Session | null = null

function token(): string | null {
  return session.get()?.token ?? memorySession?.token ?? null
}

const API_BASE = `${import.meta.env.VITE_API_BASE ?? ''}/api/v1`

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  body?: unknown
  query?: Record<string, string | number | boolean | undefined | null>
  signal?: AbortSignal
}

export async function request<T>(path: string, opts: RequestOptions = {}): Promise<{ data: T; meta?: Meta }> {
  const url = new URL(API_BASE + path, window.location.origin)
  for (const [k, v] of Object.entries(opts.query ?? {})) {
    if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, String(v))
  }
  const headers: Record<string, string> = { Accept: 'application/json' }
  const t = token()
  if (t) headers.Authorization = `Bearer ${t}`
  if (opts.body !== undefined) headers['Content-Type'] = 'application/json'

  let res: Response
  try {
    res = await fetch(url, {
      method: opts.method ?? 'GET',
      headers,
      body: opts.body === undefined ? undefined : JSON.stringify(opts.body),
      signal: opts.signal,
    })
  } catch (e) {
    if ((e as Error).name === 'AbortError') throw e
    throw new ApiError('Tidak dapat terhubung ke server. Periksa koneksi internet.', 'offline', 0)
  }
  return parse<T>(res)
}

async function parse<T>(res: Response): Promise<{ data: T; meta?: Meta }> {
  let body: { success?: boolean; data?: T; meta?: Meta; error?: { code: string; message: string; fields?: Record<string, string> } }
  try {
    body = await res.json()
  } catch {
    throw new ApiError(`Respons server tidak valid (${res.status})`, 'bad_response', res.status)
  }
  if (res.status === 401) {
    session.clear()
    window.dispatchEvent(new Event(UNAUTHORIZED_EVENT))
  }
  if (!res.ok || !body.success) {
    const err = body.error
    throw new ApiError(err?.message ?? `Terjadi kesalahan (${res.status})`, err?.code ?? 'unknown', res.status, err?.fields ?? {})
  }
  return { data: body.data as T, meta: body.meta }
}

export async function login(email: string, password: string): Promise<Session> {
  const { data } = await request<Session>('/auth/login', { method: 'POST', body: { email, password } })
  session.set(data)
  return data
}

export interface UploadedFile {
  url: string
  bucket: string
  name: string
  size: number
}

/** Upload file dengan progres (fetch belum mendukung progres upload). */
export function upload(bucket: string, file: Blob, onProgress?: (fraction: number) => void): Promise<UploadedFile> {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest()
    xhr.open('POST', `${API_BASE}/admin/uploads?bucket=${encodeURIComponent(bucket)}`)
    const t = token()
    if (t) xhr.setRequestHeader('Authorization', `Bearer ${t}`)
    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable) onProgress?.(e.loaded / e.total)
    }
    xhr.onerror = () => reject(new ApiError('Upload gagal. Periksa koneksi internet.', 'offline', 0))
    xhr.onload = () => {
      const res = new Response(xhr.responseText, { status: xhr.status })
      parse<UploadedFile>(res).then(({ data }) => resolve(data), reject)
    }
    const form = new FormData()
    form.append('file', file, file instanceof File ? file.name : 'upload')
    xhr.send(form)
  })
}

/** Hapus file hasil upload; URL dari luar server (mis. Google Drive) diabaikan. */
export async function deleteUploadedFile(url: string | null | undefined): Promise<void> {
  if (!url) return
  let parsed: URL
  try {
    parsed = new URL(url, window.location.origin)
  } catch {
    return
  }
  const m = parsed.pathname.match(/^\/files\/([a-z-]+)\/([0-9a-f]{32}\.(?:jpg|png|webp|pdf))$/)
  if (!m) return
  await request(`/admin/uploads/${m[1]}/${m[2]}`, { method: 'DELETE' })
}
