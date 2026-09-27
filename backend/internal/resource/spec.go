// Package resource menyediakan CRUD generik berbasis deklarasi.
//
// Setiap jenis konten (agenda, galeri, dokumen, ...) cukup dideklarasikan sekali
// sebagai Resource di registry.go: nama tabel, daftar field beserta aturan
// validasinya, urutan, dan filter. Validasi, query SQL, dan handler HTTP
// dipakai bersama sehingga menambah konten baru = tambah migrasi + tambah spec.
//
// Nama tabel dan kolom hanya berasal dari spec (bukan dari input pengguna),
// sedangkan nilai selalu dikirim sebagai parameter query ($1, $2, ...).
package resource

// FieldType adalah tipe data sebuah field.
type FieldType int

// Tipe field yang didukung.
const (
	Text FieldType = iota
	Int
	Bool
	Timestamp
)

// defaultMaxLen dipakai bila Field.MaxLen tidak diisi.
const defaultMaxLen = 5000

// Field mendeskripsikan satu kolom yang boleh ditulis lewat API.
type Field struct {
	Name     string
	Type     FieldType
	Required bool     // wajib ada & tidak kosong saat create; tidak boleh null saat update
	NotNull  bool     // boleh tidak dikirim, tapi bila dikirim tidak boleh null
	MaxLen   int      // khusus Text
	URL      bool     // khusus Text: harus diawali http:// atau https://
	OneOf    []string // khusus Text: nilai yang diizinkan
	Min, Max *int     // khusus Int
}

// Resource mendeskripsikan satu tabel yang diekspos lewat API.
type Resource struct {
	Path        string   // segmen URL, mis. "profil-ruangan"
	Table       string   // nama tabel PostgreSQL
	Fields      []Field  // kolom yang bisa ditulis
	OrderBy     string   // klausa ORDER BY (konstanta)
	Filters     []string // nama field yang boleh dipakai sebagai query param filter
	Distinct    []string // field integer yang punya endpoint GET /{Path}/{field} (nilai unik)
	PublicWhere string   // kondisi tambahan untuk endpoint publik, mis. "is_active"
	Singleton   bool     // tabel satu baris (konfigurasi)
	UpsertKey   string   // bila diisi, create memakai ON CONFLICT (UpsertKey) DO UPDATE
}

func (r Resource) field(name string) (Field, bool) {
	for _, f := range r.Fields {
		if f.Name == name {
			return f, true
		}
	}
	return Field{}, false
}

func intPtr(v int) *int { return &v }
