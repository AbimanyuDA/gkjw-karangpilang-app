import { Navigate, useParams } from 'react-router-dom'
import { useSchema } from '../lib/queries'
import { ResourcePage } from './ResourcePage'
import { SingletonPage } from './SingletonPage'

/** /k/:path → halaman daftar atau form satu halaman, sesuai skema dari server. */
export function ContentRoute() {
  const { path } = useParams()
  const { data: schema, isLoading } = useSchema()
  if (isLoading || !schema) return <div className="page"><span className="spinner" aria-label="Memuat" /></div>
  const resource = schema.resources.find((r) => r.path === path)
  if (!resource) return <Navigate to="/" replace />
  return resource.singleton ? (
    <SingletonPage key={resource.path} resource={resource} schema={schema} />
  ) : (
    <ResourcePage key={resource.path} resource={resource} schema={schema} />
  )
}
