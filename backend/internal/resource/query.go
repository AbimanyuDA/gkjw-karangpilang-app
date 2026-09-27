package resource

import (
	"fmt"
	"strings"
)

// ListQuery adalah parameter untuk mengambil daftar data.
type ListQuery struct {
	Filters map[string]any // nama field → nilai (sudah divalidasi)
	Public  bool           // terapkan Resource.PublicWhere
	Limit   int
	Offset  int
}

// selectColumns mengembalikan daftar kolom SELECT; id di-cast ke text agar
// uuid terserialisasi sebagai string di JSON.
func (r Resource) selectColumns() string {
	cols := make([]string, 0, len(r.Fields)+3)
	cols = append(cols, "id::text AS id")
	for _, f := range r.Fields {
		cols = append(cols, f.Name)
	}
	cols = append(cols, "created_at", "updated_at")
	return strings.Join(cols, ", ")
}

// whereClause membangun WHERE dari filter; urutan mengikuti r.Filters agar deterministik.
func (r Resource) whereClause(q ListQuery, args []any) (string, []any) {
	var conds []string
	if q.Public && r.PublicWhere != "" {
		conds = append(conds, r.PublicWhere)
	}
	for _, name := range r.Filters {
		if v, ok := q.Filters[name]; ok {
			args = append(args, v)
			conds = append(conds, fmt.Sprintf("%s = $%d", name, len(args)))
		}
	}
	if len(conds) == 0 {
		return "", args
	}
	return " WHERE " + strings.Join(conds, " AND "), args
}

func (r Resource) buildList(q ListQuery) (string, []any) {
	where, args := r.whereClause(q, nil)
	args = append(args, q.Limit, q.Offset)
	sql := fmt.Sprintf("SELECT %s FROM %s%s ORDER BY %s LIMIT $%d OFFSET $%d",
		r.selectColumns(), r.Table, where, r.orderBy(), len(args)-1, len(args))
	return sql, args
}

func (r Resource) buildCount(q ListQuery) (string, []any) {
	where, args := r.whereClause(q, nil)
	return fmt.Sprintf("SELECT count(*) FROM %s%s", r.Table, where), args
}

func (r Resource) buildGet(id string, public bool) (string, []any) {
	sql := fmt.Sprintf("SELECT %s FROM %s WHERE id = $1", r.selectColumns(), r.Table)
	if public && r.PublicWhere != "" {
		sql += " AND " + r.PublicWhere
	}
	return sql, []any{id}
}

func (r Resource) buildInsert(values map[string]any) (string, []any) {
	cols, placeholders, args := r.orderedValues(values, 0)
	sql := fmt.Sprintf("INSERT INTO %s (%s) VALUES (%s)",
		r.Table, strings.Join(cols, ", "), strings.Join(placeholders, ", "))

	if r.UpsertKey != "" {
		sets := make([]string, 0, len(cols))
		for _, c := range cols {
			if c != r.UpsertKey {
				sets = append(sets, fmt.Sprintf("%s = EXCLUDED.%s", c, c))
			}
		}
		sets = append(sets, "updated_at = now()")
		sql += fmt.Sprintf(" ON CONFLICT (%s) DO UPDATE SET %s", r.UpsertKey, strings.Join(sets, ", "))
	}
	return sql + " RETURNING " + r.selectColumns(), args
}

func (r Resource) buildUpdate(id string, values map[string]any) (string, []any) {
	cols, placeholders, args := r.orderedValues(values, 1)
	sets := make([]string, 0, len(cols)+1)
	for i, c := range cols {
		sets = append(sets, c+" = "+placeholders[i])
	}
	sets = append(sets, "updated_at = now()")
	sql := fmt.Sprintf("UPDATE %s SET %s WHERE id = $1 RETURNING %s",
		r.Table, strings.Join(sets, ", "), r.selectColumns())
	return sql, append([]any{id}, args...)
}

func (r Resource) buildDelete(id string) (string, []any) {
	return fmt.Sprintf("DELETE FROM %s WHERE id = $1", r.Table), []any{id}
}

// buildUpsertSingleton menulis baris id=1 (dibuat bila belum ada).
func (r Resource) buildUpsertSingleton(values map[string]any) (string, []any) {
	cols, placeholders, args := r.orderedValues(values, 0)
	sets := make([]string, 0, len(cols)+1)
	for _, c := range cols {
		sets = append(sets, fmt.Sprintf("%s = EXCLUDED.%s", c, c))
	}
	sets = append(sets, "updated_at = now()")
	sql := fmt.Sprintf("INSERT INTO %s (id, %s) VALUES (1, %s) ON CONFLICT (id) DO UPDATE SET %s RETURNING %s",
		r.Table, strings.Join(cols, ", "), strings.Join(placeholders, ", "),
		strings.Join(sets, ", "), r.selectColumns())
	return sql, args
}

func (r Resource) buildGetSingleton() string {
	return fmt.Sprintf("SELECT %s FROM %s WHERE id = 1", r.selectColumns(), r.Table)
}

// orderedValues mengurutkan nilai sesuai urutan field di spec agar SQL deterministik.
// offset = jumlah placeholder yang sudah dipakai sebelumnya.
func (r Resource) orderedValues(values map[string]any, offset int) (cols, placeholders []string, args []any) {
	for _, f := range r.Fields {
		v, ok := values[f.Name]
		if !ok {
			continue
		}
		args = append(args, v)
		cols = append(cols, f.Name)
		placeholders = append(placeholders, fmt.Sprintf("$%d", offset+len(args)))
	}
	return cols, placeholders, args
}

func (r Resource) orderBy() string {
	if r.OrderBy == "" {
		return "created_at DESC"
	}
	return r.OrderBy
}
