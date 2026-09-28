import { describe, expect, it } from 'vitest'
import { cropQuality, outputSize, ratioLabel, specLabel, uncroppedWarning } from './crop'
import type { ImageSpec } from './schema'

const banner: ImageSpec = { aspect_w: 16, aspect_h: 9, width: 1280, height: 720, min_width: 800, min_height: 450, crop: true, round: false }

describe('crop helpers', () => {
  it('labels the spec', () => {
    expect(ratioLabel(banner)).toBe('16:9')
    expect(specLabel(banner)).toBe('Rasio 16:9 · ideal 1280 × 720 px · min. 800 × 450 px')
  })

  it('scales a large crop down to the ideal size', () => {
    expect(outputSize({ x: 0, y: 0, width: 3200, height: 1800 }, banner)).toEqual({ width: 1280, height: 720 })
  })

  it('never upscales a small crop', () => {
    expect(outputSize({ x: 0, y: 0, width: 960, height: 540 }, banner)).toEqual({ width: 960, height: 540 })
  })

  it('flags crops below the minimum as low quality', () => {
    expect(cropQuality({ x: 0, y: 0, width: 1000, height: 562 }, banner)).toBe('ok')
    expect(cropQuality({ x: 0, y: 0, width: 640, height: 360 }, banner)).toBe('low')
  })

  it('warns about small uncropped photos', () => {
    expect(uncroppedWarning(2000, 1500, banner)).toBeNull()
    expect(uncroppedWarning(600, 400, banner)).toContain('600 × 400 px')
  })
})
