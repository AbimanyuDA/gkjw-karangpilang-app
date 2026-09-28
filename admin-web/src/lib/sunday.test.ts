import { describe, expect, it } from 'vitest'
import { countdownLabel, daysUntil, isSameDay, toDateParam, upcomingSunday } from './sunday'

describe('upcomingSunday', () => {
  it('returns today when today is Sunday', () => {
    const sunday = new Date(2026, 9, 4, 15, 30) // Minggu, 4 Okt 2026
    expect(toDateParam(upcomingSunday(sunday))).toBe('2026-10-04')
  })
  it('returns the next Sunday on other days', () => {
    expect(toDateParam(upcomingSunday(new Date(2026, 8, 27 + 1)))).toBe('2026-10-04') // Senin
    expect(toDateParam(upcomingSunday(new Date(2026, 9, 3, 23, 59)))).toBe('2026-10-04') // Sabtu malam
  })
  it('crosses month and year boundaries', () => {
    expect(toDateParam(upcomingSunday(new Date(2026, 11, 29)))).toBe('2027-01-03')
  })
})

describe('daysUntil & countdownLabel', () => {
  const sunday = new Date(2026, 9, 4)
  it('counts calendar days', () => {
    expect(daysUntil(sunday, new Date(2026, 9, 1, 22, 0))).toBe(3)
    expect(countdownLabel(3)).toBe('3 hari lagi')
    expect(countdownLabel(1)).toBe('Besok')
    expect(countdownLabel(0)).toBe('Hari ini')
  })
})

describe('isSameDay', () => {
  const sunday = new Date(2026, 9, 4)
  it('compares local calendar days', () => {
    expect(isSameDay(new Date(2026, 9, 4, 7, 0).toISOString(), sunday)).toBe(true)
    expect(isSameDay(new Date(2026, 9, 5, 0, 0).toISOString(), sunday)).toBe(false)
    expect(isSameDay(null, sunday)).toBe(false)
  })
})
