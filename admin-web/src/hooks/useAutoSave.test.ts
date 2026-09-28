import { act, renderHook } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useAutoSave } from './useAutoSave'

beforeEach(() => vi.useFakeTimers())
afterEach(() => vi.useRealTimers())

function setup(save: (s: string) => Promise<void>, initial = 'a', blocked = false) {
  return renderHook((props: { snapshot: string; blocked: boolean }) => useAutoSave({ ...props, save, delay: 1000 }), {
    initialProps: { snapshot: initial, blocked },
  })
}

describe('useAutoSave', () => {
  it('tidak menyimpan bila tidak ada perubahan', async () => {
    const save = vi.fn(async () => {})
    const { result } = setup(save)
    await act(() => vi.advanceTimersByTimeAsync(5000))
    expect(save).not.toHaveBeenCalled()
    expect(result.current.dirty).toBe(false)
    expect(result.current.status).toBe('idle')
  })

  it('menyimpan sekali setelah jeda dari perubahan terakhir', async () => {
    const save = vi.fn(async () => {})
    const { result, rerender } = setup(save)
    rerender({ snapshot: 'ab', blocked: false })
    await act(() => vi.advanceTimersByTimeAsync(500))
    rerender({ snapshot: 'abc', blocked: false })
    expect(result.current.status).toBe('pending')
    await act(() => vi.advanceTimersByTimeAsync(999))
    expect(save).not.toHaveBeenCalled()
    await act(() => vi.advanceTimersByTimeAsync(1))
    expect(save).toHaveBeenCalledTimes(1)
    expect(save).toHaveBeenCalledWith('abc')
    expect(result.current.status).toBe('saved')
    expect(result.current.dirty).toBe(false)
    expect(result.current.savedAt).toBeInstanceOf(Date)
  })

  it('menunggu upload selesai sebelum menyimpan', async () => {
    const save = vi.fn(async () => {})
    const { rerender } = setup(save)
    rerender({ snapshot: 'b', blocked: true })
    await act(() => vi.advanceTimersByTimeAsync(5000))
    expect(save).not.toHaveBeenCalled()
    rerender({ snapshot: 'b', blocked: false })
    await act(() => vi.advanceTimersByTimeAsync(1000))
    expect(save).toHaveBeenCalledWith('b')
  })

  it('perubahan saat menyimpan ikut disimpan sesudahnya', async () => {
    let finish = () => {}
    const save = vi.fn((s: string) => (s === 'b' ? new Promise<void>((r) => (finish = r)) : Promise.resolve()))
    const { result, rerender } = setup(save)
    rerender({ snapshot: 'b', blocked: false })
    await act(() => vi.advanceTimersByTimeAsync(1000))
    expect(result.current.status).toBe('saving')
    rerender({ snapshot: 'bc', blocked: false })
    await act(async () => finish())
    await act(() => vi.advanceTimersByTimeAsync(1000))
    expect(save.mock.calls.map((c) => c[0])).toEqual(['b', 'bc'])
    expect(result.current.status).toBe('saved')
  })

  it('gagal: status error, tidak mengulang terus, bisa disimpan manual', async () => {
    const save = vi.fn().mockRejectedValueOnce(new Error('Server mati')).mockResolvedValue(undefined)
    const { result, rerender } = setup(save)
    rerender({ snapshot: 'b', blocked: false })
    await act(() => vi.advanceTimersByTimeAsync(1000))
    expect(result.current.status).toBe('error')
    expect(result.current.error).toBe('Server mati')
    await act(() => vi.advanceTimersByTimeAsync(10_000))
    expect(save).toHaveBeenCalledTimes(1)
    await act(() => result.current.saveNow())
    expect(save).toHaveBeenCalledTimes(2)
    expect(result.current.status).toBe('saved')
  })
})
