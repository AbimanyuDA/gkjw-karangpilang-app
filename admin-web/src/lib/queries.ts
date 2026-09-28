import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { request, type Meta } from './api'
import type { AdminSchema, ResourceSchema, Row } from './schema'

export const PAGE_SIZE = 25

export function useSchema() {
  return useQuery({
    queryKey: ['schema'],
    queryFn: async () => (await request<AdminSchema>('/admin/schema')).data,
    staleTime: Infinity,
  })
}

export function useResource(path: string | undefined): ResourceSchema | undefined {
  const { data } = useSchema()
  return data?.resources.find((r) => r.path === path)
}

export interface ListParams {
  offset?: number
  limit?: number
  filters?: Record<string, string>
}

export function useList(path: string, params: ListParams = {}) {
  return useQuery({
    queryKey: ['list', path, params],
    queryFn: async (): Promise<{ rows: Row[]; meta?: Meta }> => {
      const { data, meta } = await request<Row[]>(`/admin/${path}`, {
        query: { limit: params.limit ?? PAGE_SIZE, offset: params.offset ?? 0, ...params.filters },
      })
      return { rows: data, meta }
    },
    placeholderData: keepPreviousData,
  })
}

export function useSingleton(path: string) {
  return useQuery({
    queryKey: ['singleton', path],
    queryFn: async () => (await request<Row | null>(`/admin/${path}`)).data,
  })
}

/** Simpan (tambah/ubah) satu baris; semua daftar resource ini disegarkan. */
export function useSave(resource: ResourceSchema) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, body }: { id?: string; body: Record<string, unknown> }) => {
      if (resource.singleton) return (await request<Row>(`/admin/${resource.path}`, { method: 'PUT', body })).data
      if (id) return (await request<Row>(`/admin/${resource.path}/${id}`, { method: 'PUT', body })).data
      return (await request<Row>(`/admin/${resource.path}`, { method: 'POST', body })).data
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['list', resource.path] })
      qc.invalidateQueries({ queryKey: ['singleton', resource.path] })
      qc.invalidateQueries({ queryKey: ['sunday'] })
    },
  })
}

/** Simpan urutan baru hasil drag (id pertama = paling atas). */
export function useReorder(resource: ResourceSchema) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (ids: string[]) => request(`/admin/${resource.path}/urutan`, { method: 'PUT', body: { ids } }),
    onSettled: () => qc.invalidateQueries({ queryKey: ['list', resource.path] }),
  })
}

export function useDelete(resource: ResourceSchema) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => request(`/admin/${resource.path}/${id}`, { method: 'DELETE' }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['list', resource.path] })
      qc.invalidateQueries({ queryKey: ['sunday'] })
    },
  })
}
