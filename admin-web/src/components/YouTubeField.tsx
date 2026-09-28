import { useState } from 'react'
import { Loader2, Wand2 } from 'lucide-react'
import { ApiError, request } from '../lib/api'
import { toDateInput } from '../lib/form'
import { extractVideoId } from '../lib/youtube'

export interface YouTubeMetadata {
  youtube_id: string
  judul: string
  deskripsi: string
  tanggal: string | null
  thumbnail: string
}

interface Props {
  id: string
  value: string
  onChange: (videoId: string) => void
  /** Isi otomatis field lain (judul, deskripsi, tanggal) dari data video. */
  onFetched: (fill: Record<string, string>) => void
}

/** Tempel link YouTube → judul, deskripsi & tanggal terisi otomatis (tanpa API key Google). */
export function YouTubeField({ id, value, onChange, onFetched }: Props) {
  const [text, setText] = useState(value)
  const [status, setStatus] = useState<'idle' | 'loading' | 'error'>('idle')
  const [message, setMessage] = useState('')

  async function fetchMeta(link: string) {
    const videoId = extractVideoId(link)
    if (!videoId) {
      setStatus('error')
      setMessage('Link YouTube tidak dikenali.')
      return
    }
    onChange(videoId)
    setStatus('loading')
    try {
      const { data } = await request<YouTubeMetadata>('/admin/youtube', { query: { url: link } })
      onFetched({
        judul: data.judul,
        deskripsi: data.deskripsi,
        ...(data.tanggal ? { tanggal: toDateInput(data.tanggal, false) } : {}),
      })
      setStatus('idle')
      setMessage('Judul, deskripsi & tanggal terisi dari YouTube — periksa lagi sebelum menyimpan.')
    } catch (e) {
      setStatus('error')
      setMessage(e instanceof ApiError ? e.message : 'Data video gagal diambil. Isi manual.')
    }
  }

  const videoId = extractVideoId(text) ?? (value || null)
  return (
    <div className="youtube-field">
      <div className="input-with-action">
        <input
          id={id}
          className="input"
          value={text}
          placeholder="https://www.youtube.com/watch?v=…"
          onChange={(e) => {
            setText(e.target.value)
            const vid = extractVideoId(e.target.value)
            if (vid) onChange(vid)
          }}
          onPaste={(e) => {
            const pasted = e.clipboardData.getData('text')
            if (extractVideoId(pasted)) setTimeout(() => fetchMeta(pasted))
          }}
        />
        <button type="button" className="btn btn-secondary" disabled={!text || status === 'loading'} onClick={() => fetchMeta(text)}>
          {status === 'loading' ? <Loader2 size={15} className="spin" aria-hidden /> : <Wand2 size={15} aria-hidden />}
          Ambil data
        </button>
      </div>
      {videoId && (
        <img className="youtube-thumb" src={`https://img.youtube.com/vi/${videoId}/mqdefault.jpg`} alt="Thumbnail video" width={240} height={135} />
      )}
      {message && <p className={status === 'error' ? 'field-error' : 'field-help'}>{message}</p>}
    </div>
  )
}
