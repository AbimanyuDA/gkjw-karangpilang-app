import { ResourceForm } from '../components/ResourceForm'
import { useSingleton } from '../lib/queries'
import type { AdminSchema, ResourceSchema } from '../lib/schema'

/** Konten satu halaman (Informasi Gereja, Tentang Aplikasi, Sapaan Harian): langsung berupa form. */
export function SingletonPage({ resource, schema }: { resource: ResourceSchema; schema: AdminSchema }) {
  const q = useSingleton(resource.path)
  return (
    <div className="page page-narrow">
      <header className="page-head">
        <div>
          <div className="eyebrow">{resource.group}</div>
          <h1>{resource.label}</h1>
          {resource.description && <p className="page-desc">{resource.description}</p>}
        </div>
      </header>
      <div className="form-card">
        {q.isLoading ? (
          <span className="spinner" aria-label="Memuat" />
        ) : q.isError ? (
          <p className="form-error">Data gagal dimuat: {(q.error as Error).message}</p>
        ) : (
          <ResourceForm key={q.dataUpdatedAt} resource={resource} buckets={schema.buckets} row={q.data} />
        )}
      </div>
    </div>
  )
}
