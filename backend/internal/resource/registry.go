package resource

// Definisi field yang dipakai berulang.
var (
	urutanField = Field{Name: "urutan", Type: Int, NotNull: true, Min: intPtr(0), Max: intPtr(100000)}
	fotoField   = Field{Name: "foto_url", Type: Text, URL: true, MaxLen: 1000}
)

// All adalah daftar seluruh konten yang diekspos API.
// Menambah konten baru: buat migrasi tabel, lalu tambahkan entri di sini.
var All = []Resource{
	{
		Path:  "banners",
		Table: "banner_slide",
		Fields: []Field{
			{Name: "image_url", Type: Text, Required: true, URL: true, MaxLen: 1000},
			{Name: "judul", Type: Text, MaxLen: 200},
			{Name: "link_url", Type: Text, URL: true, MaxLen: 1000},
			urutanField,
			{Name: "is_active", Type: Bool, NotNull: true},
		},
		OrderBy:     "urutan ASC, created_at ASC",
		PublicWhere: "is_active",
	},
	{
		Path:  "galeri",
		Table: "galeri",
		Fields: []Field{
			{Name: "judul", Type: Text, Required: true, MaxLen: 200},
			{Name: "deskripsi", Type: Text},
			{Name: "tahun", Type: Int, Required: true, Min: intPtr(1900), Max: intPtr(2200)},
			{Name: "komisi", Type: Text, MaxLen: 200},
			{Name: "foto_url", Type: Text, Required: true, URL: true, MaxLen: 1000},
		},
		OrderBy:  "tahun DESC, created_at DESC",
		Filters:  []string{"tahun"},
		Distinct: []string{"tahun"},
	},
	{
		Path:  "agenda",
		Table: "agenda",
		Fields: []Field{
			{Name: "judul", Type: Text, Required: true, MaxLen: 200},
			{Name: "deskripsi", Type: Text},
			{Name: "tanggal", Type: Timestamp, Required: true},
			{Name: "tempat", Type: Text, MaxLen: 300},
		},
		OrderBy: "tanggal ASC",
	},
	profilResource("kependetaan"),
	profilResource("kemajelisan"),
	kelompokResource("bpm", "bpm"),
	kelompokResource("perwilayahan", "perwilayahan"),
	{
		Path:  "profil-ruangan",
		Table: "profil_ruangan",
		Fields: []Field{
			{Name: "nama", Type: Text, Required: true, MaxLen: 200},
			{Name: "kapasitas", Type: Int, Min: intPtr(0), Max: intPtr(100000)},
			{Name: "deskripsi", Type: Text},
			fotoField,
			urutanField,
		},
		OrderBy: "urutan ASC, created_at ASC",
	},
	{
		Path:  "eperpus",
		Table: "eperpus",
		Fields: []Field{
			{Name: "judul", Type: Text, Required: true, MaxLen: 300},
			{Name: "penulis", Type: Text, MaxLen: 200},
			{Name: "deskripsi", Type: Text},
			{Name: "cover_url", Type: Text, URL: true, MaxLen: 1000},
			{Name: "file_url", Type: Text, Required: true, URL: true, MaxLen: 1000},
			{Name: "tahun", Type: Int, Min: intPtr(1500), Max: intPtr(2200)},
		},
		OrderBy: "created_at DESC",
	},
	{
		Path:  "inspirasi",
		Table: "inspirasi",
		Fields: []Field{
			{Name: "kategori", Type: Text, Required: true, MaxLen: 50},
			{Name: "teks", Type: Text, Required: true, MaxLen: 1000},
			{Name: "warna", Type: Text, NotNull: true, MaxLen: 20},
		},
		OrderBy: "created_at ASC",
		Filters: []string{"kategori"},
	},
	{
		Path:  "notifikasi",
		Table: "notifikasi",
		Fields: []Field{
			{Name: "judul", Type: Text, Required: true, MaxLen: 200},
			{Name: "pesan", Type: Text, Required: true, MaxLen: 2000},
			{Name: "is_active", Type: Bool, NotNull: true},
		},
		OrderBy:     "created_at DESC",
		PublicWhere: "is_active",
	},
	{
		Path:  "faq",
		Table: "faq",
		Fields: []Field{
			{Name: "pertanyaan", Type: Text, Required: true, MaxLen: 500},
			{Name: "jawaban", Type: Text, Required: true},
			urutanField,
		},
		OrderBy: "urutan ASC, created_at ASC",
	},
	{
		Path:  "hubungi-kami",
		Table: "hubungi_kami",
		Fields: []Field{
			{Name: "nama", Type: Text, Required: true, MaxLen: 200},
			{Name: "jenis", Type: Text, Required: true, MaxLen: 50},
			{Name: "nilai", Type: Text, Required: true, MaxLen: 1000},
			{Name: "ikon", Type: Text, MaxLen: 100},
			urutanField,
		},
		OrderBy: "urutan ASC, created_at ASC",
	},
	{
		// Warta Jemaat, Tata Ibadah, dan Renungan (dulu 3 koleksi Firestore).
		Path:  "dokumen",
		Table: "dokumen",
		Fields: []Field{
			{Name: "kategori", Type: Text, Required: true, OneOf: []string{"warta", "tata_ibadah", "renungan"}},
			{Name: "judul", Type: Text, Required: true, MaxLen: 300},
			{Name: "url", Type: Text, Required: true, URL: true, MaxLen: 1000},
			{Name: "tanggal", Type: Timestamp, Required: true},
			{Name: "thumbnail", Type: Text, URL: true, MaxLen: 1000},
		},
		OrderBy: "tanggal DESC, created_at DESC",
		Filters: []string{"kategori"},
	},
	{
		Path:  "siaran",
		Table: "siaran",
		Fields: []Field{
			{Name: "judul", Type: Text, Required: true, MaxLen: 300},
			{Name: "youtube_id", Type: Text, Required: true, MaxLen: 20},
			{Name: "kategori", Type: Text, Required: true, OneOf: []string{"umum", "anak", "remaja", "sekolah_minggu"}},
			{Name: "tanggal", Type: Timestamp, Required: true},
			{Name: "thumbnail", Type: Text, URL: true, MaxLen: 1000},
			{Name: "deskripsi", Type: Text},
		},
		OrderBy: "tanggal DESC, created_at DESC",
		Filters: []string{"kategori"},
	},
	{
		Path:  "gereja-covers",
		Table: "gereja_covers",
		Fields: []Field{
			{Name: "key", Type: Text, Required: true, OneOf: []string{
				"informasi_gereja", "kependetaan", "kemajelisan", "bpm", "perwilayahan", "profil_ruangan",
			}},
			{Name: "image_url", Type: Text, Required: true, URL: true, MaxLen: 1000},
		},
		OrderBy:   "key ASC",
		UpsertKey: "key",
	},
	{
		Path:      "informasi-gereja",
		Table:     "informasi_gereja",
		Singleton: true,
		Fields: []Field{
			{Name: "nama", Type: Text, MaxLen: 200},
			{Name: "alamat", Type: Text, MaxLen: 500},
			{Name: "deskripsi", Type: Text},
			{Name: "visi", Type: Text},
			{Name: "misi", Type: Text},
			{Name: "telepon", Type: Text, MaxLen: 50},
			{Name: "email", Type: Text, MaxLen: 200},
			{Name: "maps_url", Type: Text, URL: true, MaxLen: 1000},
		},
	},
	{
		Path:      "tentang-aplikasi",
		Table:     "tentang_aplikasi",
		Singleton: true,
		Fields: []Field{
			{Name: "versi", Type: Text, MaxLen: 50},
			{Name: "deskripsi", Type: Text},
			{Name: "tim_pengembang", Type: Text},
		},
	},
	{
		Path:      "sapaan-config",
		Table:     "sapaan_config",
		Singleton: true,
		Fields: []Field{
			{Name: "jam_pagi", Type: Int, NotNull: true, Min: intPtr(0), Max: intPtr(23)},
			{Name: "menit_pagi", Type: Int, NotNull: true, Min: intPtr(0), Max: intPtr(59)},
			{Name: "jam_malam", Type: Int, NotNull: true, Min: intPtr(0), Max: intPtr(23)},
			{Name: "menit_malam", Type: Int, NotNull: true, Min: intPtr(0), Max: intPtr(59)},
			{Name: "ayat_pagi", Type: Text, NotNull: true, MaxLen: 1000},
			{Name: "ayat_malam", Type: Text, NotNull: true, MaxLen: 1000},
		},
	},
}

// profilResource: daftar orang dengan jabatan (kependetaan, kemajelisan).
func profilResource(table string) Resource {
	return Resource{
		Path:  table,
		Table: table,
		Fields: []Field{
			{Name: "nama", Type: Text, Required: true, MaxLen: 200},
			{Name: "jabatan", Type: Text, Required: true, MaxLen: 200},
			fotoField,
			{Name: "bio", Type: Text},
			{Name: "komisi", Type: Text, MaxLen: 200},
			urutanField,
		},
		OrderBy: "urutan ASC, created_at ASC",
	}
}

// kelompokResource: kelompok dengan ketua (BPM, perwilayahan).
func kelompokResource(path, table string) Resource {
	return Resource{
		Path:  path,
		Table: table,
		Fields: []Field{
			{Name: "nama", Type: Text, Required: true, MaxLen: 200},
			{Name: "ketua", Type: Text, MaxLen: 200},
			{Name: "deskripsi", Type: Text},
			fotoField,
			urutanField,
		},
		OrderBy: "urutan ASC, created_at ASC",
	}
}
