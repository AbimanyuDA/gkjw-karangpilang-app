import { describe, expect, it } from 'vitest'
import { extractVideoId } from './youtube'

describe('extractVideoId', () => {
  const id = 'dQw4w9WgXcQ'
  it.each([
    `https://www.youtube.com/watch?v=${id}`,
    `https://www.youtube.com/watch?feature=share&v=${id}&t=10`,
    `https://youtu.be/${id}?si=abc`,
    `https://www.youtube.com/live/${id}`,
    `https://youtube.com/shorts/${id}`,
    `  ${id}  `,
  ])('%s', (input) => expect(extractVideoId(input)).toBe(id))

  it('rejects other text', () => {
    expect(extractVideoId('https://example.com/video')).toBeNull()
    expect(extractVideoId('')).toBeNull()
  })
})
