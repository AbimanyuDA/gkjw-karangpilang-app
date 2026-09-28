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

// Input adalah jenis kontrol form yang dipakai website admin.
type Input string

// Jenis input form admin. Kosong = diturunkan dari FieldType.
const (
	InputText     Input = "text"
	InputTextarea Input = "textarea"
	InputURL      Input = "url"
	InputImage    Input = "image" // upload gambar ke bucket Field.Upload
	InputPDF      Input = "pdf"   // upload PDF ke bucket Field.Upload
	InputColor    Input = "color"
	InputSelect   Input = "select"
	InputNumber   Input = "number"
	InputSwitch   Input = "switch"
	InputDateTime Input = "datetime"
	InputDate     Input = "date"
	InputYouTube  Input = "youtube" // ID video; admin bisa menempel link lengkap
)

// ImageSpec adalah panduan ukuran gambar sesuai cara aplikasi menampilkannya.
type ImageSpec struct {
	AspectW   int    `json:"aspect_w"` // rasio lebar, mis. 16
	AspectH   int    `json:"aspect_h"` // rasio tinggi, mis. 9
	Width     int    `json:"width"`    // ukuran ideal (px)
	Height    int    `json:"height"`
	MinWidth  int    `json:"min_width"` // di bawah ini gambar tampak pecah
	MinHeight int    `json:"min_height"`
	Note      string `json:"note,omitempty"`
	Crop      bool   `json:"crop"`  // admin wajib memotong ke rasio ini sebelum upload
	Round     bool   `json:"round"` // ditampilkan dalam lingkaran (pratinjau potong bulat)
}

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
	Pattern  string   // khusus Text: regex yang harus cocok (mis. warna hex)

	// Metadata untuk website admin (tidak memengaruhi validasi).
	Label  string
	Help   string
	Input  Input
	Upload string     // bucket upload untuk InputImage / InputPDF
	Image  *ImageSpec // panduan ukuran untuk InputImage
	// Section mengelompokkan field berurutan di form admin di bawah satu judul.
	Section string
}

// Resource mendeskripsikan satu tabel yang diekspos lewat API.
type Resource struct {
	// Metadata untuk website admin.
	Label       string   // nama menu, mis. "Warta & Tata Ibadah"
	Group       string   // kelompok menu di sidebar
	Description string   // penjelasan singkat di atas halaman
	Columns     []string // kolom yang tampil di tabel daftar
	TitleField  string   // field yang dipakai sebagai judul baris

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

// Sortable: resource punya kolom "urutan" sehingga admin bisa mengurutkan dengan drag.
func (r Resource) Sortable() bool {
	_, ok := r.field(SortField)
	return ok && !r.Singleton
}

// SortField adalah nama kolom urutan.
const SortField = "urutan"

func intPtr(v int) *int { return &v }
