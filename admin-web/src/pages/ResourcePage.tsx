import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { ChevronLeft, ChevronRight, FileText, Pencil, Plus, Trash2 } from 'lucide-react'
import { ConfirmDialog, Drawer } from '../components/Dialogs'
import { ResourceForm } from '../components/ResourceForm'
import { useToast } from '../lib/toast'
import { deleteUploadedFile, request } from '../lib/api'
import { formatDate, optionLabel } from '../lib/format'
import { PAGE_SIZE, useDelete, useList } from '../lib/queries'
import { fieldOf, type AdminSchema, type FieldSchema, type ResourceSchema, type Row } from '../lib/schema'

const PRESET_PREFIX = 'isi.' // ?baru=1&isi.kategori=warta&isi.tanggal=2026-10-04

export function ResourcePage({ resource, schema }: { resource: ResourceSchema; schema: AdminSchema }) {
  const [params, setParams] = useSearchParams()
  const toast = useToast()
  const del = useDelete(resource)
  const [toDelete, setToDelete] = useState<Row | null>(null)

  // Filter berupa pilihan (mis. kategori) ditampilkan sebagai tab.
  const tabFilter = resource.filters.map((n) => fieldOf(resource, n)).find((f) => f?.options?.length)
  const activeTab = tabFilter ? (params.get(tabFilter.name) ?? '') : ''
  const page = Math.max(1, Number(params.get('hal') ?? 1))
  const list = useList(resource.path, {
    offset: (page - 1) * PAGE_SIZE,
    filters: tabFilter && activeTab ? { [tabFilter.name]: activeTab } : undefined,
  })

  const editId = params.get('ubah')
  const creating = params.get('baru') === '1'
  const preset = Object.fromEntries(
    [...params.entries()].filter(([k]) => k.startsWith(PRESET_PREFIX)).map(([k, v]) => [k.slice(PRESET_PREFIX.length), v]),
  )
  if (creating && tabFilter && activeTab && !preset[tabFilter.name]) preset[tabFilter.name] = activeTab

  const cachedRow = list.data?.rows.find((r) => r.id === editId)
  const editing = useQuery({
    queryKey: ['row', resource.path, editId],
    queryFn: async () => (await request<Row>(`/admin/${resource.path}/${editId}`)).data,
    enabled: Boolean(editId) && !cachedRow,
  })
  const editRow = cachedRow ?? editing.data

  const update = (changes: Record<string, string | null>) =>
    setParams(
      (prev) => {
        const next = new URLSearchParams(prev)
        for (const [k, v] of Object.entries(changes)) {
          if (v === null) next.delete(k)
          else next.set(k, v)
        }
        return next
      },
      { replace: false },
    )
  const closeDrawer = () =>
    setParams((prev) => {
      const next = new URLSearchParams(prev)
      next.delete('ubah')
      next.delete('baru')
      for (const k of [...next.keys()]) if (k.startsWith(PRESET_PREFIX)) next.delete(k)
      return next
    })

  async function confirmDelete() {
    if (!toDelete) return
    try {
      await del.mutateAsync(toDelete.id)
      // Hapus juga file yang diunggah untuk baris ini (gagal hapus file tidak menggagalkan).
      await Promise.allSettled(
        resource.fields.filter((f) => f.upload).map((f) => deleteUploadedFile(toDelete[f.name] as string | null)),
      )
      toast('Data dihapus')
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Gagal menghapus', 'error')
    } finally {
      setToDelete(null)
    }
  }

  const total = list.data?.meta?.total ?? 0
  const pages = Math.max(1, Math.ceil(total / PAGE_SIZE))
  const title = (row: Row) => String(row[resource.title_field ?? resource.columns[0]] ?? '(tanpa judul)')
  const itemLabel = tabFilter && activeTab ? optionLabel(activeTab) : resource.label

  return (
    <div className="page">
      <header className="page-head">
        <div>
          <div className="eyebrow">{resource.group}</div>
          <h1>{resource.label}</h1>
          {resource.description && <p className="page-desc">{resource.description}</p>}
        </div>
        <button className="btn btn-primary" onClick={() => update({ baru: '1', ubah: null })}>
          <Plus size={17} aria-hidden /> Tambah
        </button>
      </header>

      {tabFilter && (
        <div className="tabs" role="tablist" aria-label={tabFilter.label}>
          {['', ...(tabFilter.options ?? [])].map((opt) => (
            <button key={opt || 'semua'} role="tab" aria-selected={activeTab === opt} className="tab" onClick={() => update({ [tabFilter.name]: opt || null, hal: null })}>
              {opt ? optionLabel(opt) : 'Semua'}
            </button>
          ))}
        </div>
      )}

      <div className="table-card" aria-busy={list.isFetching}>
        {list.isError ? (
          <div className="empty">
            <p>Data gagal dimuat: {(list.error as Error).message}</p>
            <button className="btn btn-secondary" onClick={() => list.refetch()}>
              Coba lagi
            </button>
          </div>
        ) : list.isLoading ? (
          <div className="empty">
            <span className="spinner" aria-label="Memuat" />
          </div>
        ) : list.data && list.data.rows.length === 0 ? (
          <div className="empty">
            <h2>Belum ada {itemLabel.toLowerCase()}</h2>
            <p>Data yang ditambahkan di sini langsung tampil di aplikasi jemaat.</p>
            <button className="btn btn-primary" onClick={() => update({ baru: '1' })}>
              <Plus size={17} aria-hidden /> Tambah {itemLabel.toLowerCase()}
            </button>
          </div>
        ) : (
          <table className="table">
            <thead>
              <tr>
                {resource.columns.map((c) => (
                  <th key={c} scope="col" data-kind={fieldOf(resource, c)?.input}>
                    {fieldOf(resource, c)?.label ?? c}
                  </th>
                ))}
                <th scope="col" className="col-actions">
                  <span className="visually-hidden">Aksi</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {list.data?.rows.map((row) => (
                <tr key={row.id} onClick={() => update({ ubah: row.id, baru: null })}>
                  {resource.columns.map((c) => (
                    <td key={c} data-kind={fieldOf(resource, c)?.input}>
                      <Cell field={fieldOf(resource, c)} value={row[c]} />
                    </td>
                  ))}
                  <td className="col-actions" onClick={(e) => e.stopPropagation()}>
                    <button className="btn btn-ghost btn-icon" aria-label={`Ubah ${title(row)}`} onClick={() => update({ ubah: row.id, baru: null })}>
                      <Pencil size={16} />
                    </button>
                    <button className="btn btn-ghost btn-icon danger" aria-label={`Hapus ${title(row)}`} onClick={() => setToDelete(row)}>
                      <Trash2 size={16} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {pages > 1 && (
        <nav className="pager" aria-label="Halaman">
          <button className="btn btn-ghost" disabled={page <= 1} onClick={() => update({ hal: String(page - 1) })}>
            <ChevronLeft size={16} aria-hidden /> Sebelumnya
          </button>
          <span>
            Halaman {page} dari {pages} · {total} data
          </span>
          <button className="btn btn-ghost" disabled={page >= pages} onClick={() => update({ hal: String(page + 1) })}>
            Berikutnya <ChevronRight size={16} aria-hidden />
          </button>
        </nav>
      )}

      {(creating || (editId && editRow)) && (
        <Drawer title={creating ? `Tambah ${itemLabel.toLowerCase()}` : title(editRow as Row)} eyebrow={creating ? resource.label : 'Ubah data'} onClose={closeDrawer}>
          <ResourceForm
            key={creating ? 'baru' : editId}
            resource={resource}
            buckets={schema.buckets}
            row={creating ? null : editRow}
            preset={preset}
            onSaved={closeDrawer}
            onCancel={closeDrawer}
          />
        </Drawer>
      )}

      {toDelete && (
        <ConfirmDialog
          title="Hapus data ini?"
          message={`"${title(toDelete)}" akan hilang dari aplikasi jemaat. Tindakan ini tidak bisa dibatalkan.`}
          confirmLabel="Hapus"
          busy={del.isPending}
          onConfirm={confirmDelete}
          onCancel={() => setToDelete(null)}
        />
      )}
    </div>
  )
}

function Cell({ field, value }: { field: FieldSchema | undefined; value: unknown }) {
  if (value === null || value === undefined || value === '') return <span className="muted">—</span>
  switch (field?.input) {
    case 'image':
      return <img className="thumb" src={String(value)} alt="" loading="lazy" width={56} height={40} />
    case 'youtube':
      return <img className="thumb" src={`https://img.youtube.com/vi/${String(value)}/default.jpg`} alt="" loading="lazy" width={56} height={40} />
    case 'pdf':
      return (
        <a href={String(value)} target="_blank" rel="noreferrer" onClick={(e) => e.stopPropagation()} className="pdf-link">
          <FileText size={15} aria-hidden /> PDF
        </a>
      )
    case 'switch':
      return value ? <span className="badge badge-ok">Tampil</span> : <span className="badge badge-muted">Disembunyikan</span>
    case 'select':
      return <span className="badge">{optionLabel(String(value))}</span>
    case 'color':
      return <span className="swatch" style={{ background: String(value) }} aria-label={String(value)} />
  }
  if (field?.type === 'timestamp') return <span className="nowrap">{formatDate(String(value), field.input === 'datetime')}</span>
  return <span className="clamp">{String(value)}</span>
}
