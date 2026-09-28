import type { ReactNode } from 'react'
import {
  DndContext,
  KeyboardSensor,
  PointerSensor,
  TouchSensor,
  closestCenter,
  useSensor,
  useSensors,
  type DragEndEvent,
} from '@dnd-kit/core'
import { SortableContext, arrayMove, sortableKeyboardCoordinates, useSortable, verticalListSortingStrategy } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { GripVertical } from 'lucide-react'
import type { Row } from '../lib/schema'

interface Props {
  rows: Row[]
  /** Isi sel baris (tanpa kolom pegangan). */
  renderCells: (row: Row) => ReactNode
  onRowClick: (row: Row) => void
  /** Dipanggil dengan urutan baru setelah baris dipindah. */
  onReorder: (rows: Row[]) => void
  label: (row: Row) => string
}

/** Isi <tbody> yang barisnya bisa diseret (mouse, sentuh, atau keyboard: Spasi lalu ↑/↓). */
export function SortableRows({ rows, renderCells, onRowClick, onReorder, label }: Props) {
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
    useSensor(TouchSensor, { activationConstraint: { delay: 150, tolerance: 5 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  )

  function handleDragEnd({ active, over }: DragEndEvent) {
    if (!over || active.id === over.id) return
    const from = rows.findIndex((r) => r.id === active.id)
    const to = rows.findIndex((r) => r.id === over.id)
    if (from < 0 || to < 0) return
    onReorder(arrayMove(rows, from, to))
  }

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragEnd={handleDragEnd}
      accessibility={{
        screenReaderInstructions: { draggable: 'Tekan Spasi untuk mengangkat, panah atas/bawah untuk memindah, Spasi lagi untuk meletakkan.' },
      }}
    >
      <SortableContext items={rows.map((r) => r.id)} strategy={verticalListSortingStrategy}>
        <tbody>
          {rows.map((row, i) => (
            <SortableRow key={row.id} row={row} position={i + 1} label={label(row)} onClick={() => onRowClick(row)}>
              {renderCells(row)}
            </SortableRow>
          ))}
        </tbody>
      </SortableContext>
    </DndContext>
  )
}

interface RowProps {
  row: Row
  position: number
  label: string
  onClick: () => void
  children: ReactNode
}

function SortableRow({ row, position, label, onClick, children }: RowProps) {
  const { attributes, listeners, setNodeRef, setActivatorNodeRef, transform, transition, isDragging } = useSortable({ id: row.id })
  return (
    <tr
      ref={setNodeRef}
      onClick={onClick}
      data-dragging={isDragging || undefined}
      style={{ transform: CSS.Translate.toString(transform), transition }}
    >
      <td className="col-drag" onClick={(e) => e.stopPropagation()}>
        <button
          type="button"
          ref={setActivatorNodeRef}
          className="drag-handle"
          aria-label={`Seret untuk memindah ${label} (posisi ${position})`}
          {...attributes}
          {...listeners}
        >
          <GripVertical size={18} aria-hidden />
          <span className="drag-pos">{position}</span>
        </button>
      </td>
      {children}
    </tr>
  )
}
