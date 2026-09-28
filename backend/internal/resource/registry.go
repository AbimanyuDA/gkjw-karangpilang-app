package resource

// Kelompok menu di website admin.
const (
	GroupIbadah    = "Ibadah"
	GroupJemaat    = "Jemaat"
	GroupProfil    = "Profil Gereja"
	GroupInformasi = "Informasi & Pengaturan"
)

// Definisi field yang dipakai berulang.
var (
	urutanField = Field{Name: "urutan", Type: Int, NotNull: true, Min: intPtr(0), Max: intPtr(100000),
		Label: "Urutan", Help: "Angka kecil tampil lebih dulu"}
	fotoField = Field{Name: "foto_url", Type: Text, URL: true, MaxLen: 1000,
		Label: "Foto", Input: InputImage, Upload: "profil"}
)

// All adalah daftar seluruh konten yang diekspos API.
// Menambah konten baru: buat migrasi tabel, lalu tambahkan entri di sini —
// endpoint API dan halaman website admin terbentuk otomatis.
var All = []Resource{
	// ── Ibadah ─────────────────────────────────────────────────────
	{
		Label:       "Warta, Tata Ibadah & Renungan",
		Group:       GroupIbadah,
		Description: "Dokumen PDF mingguan yang dibaca jemaat di aplikasi.",
		Columns:     []string{"judul", "kategori", "tanggal"},
		TitleField:  "judul",
		Path:        "dokumen",
		Table:       "dokumen",
		Fields: []Field{
			{Name: "kategori", Type: Text, Required: true, OneOf: []string{"warta", "tata_ibadah", "renungan"},
				Label: "Kategori", Input: InputSelect},
			{Name: "judul", Type: Text, Required: true, MaxLen: 300, Label: "Judul"},
			{Name: "tanggal", Type: Timestamp, Required: true, Label: "Tanggal", Input: InputDate},
			{Name: "url", Type: Text, Required: true, URL: true, MaxLen: 1000,
				Label: "File PDF", Input: InputPDF, Upload: "dokumen"},
			{Name: "thumbnail", Type: Text, URL: true, MaxLen: 1000, Label: "Gambar sampul", Input: InputImage, Upload: "dokumen-cover"},
		},
		OrderBy: "tanggal DESC, created_at DESC",
		Filters: []string{"kategori"},
	},
	{
		Label:       "Video Siaran",
		Group:       GroupIbadah,
		Description: "Tempel link YouTube — judul, deskripsi, dan tanggal terisi otomatis.",
		Columns:     []string{"judul", "kategori", "tanggal"},
		TitleField:  "judul",
		Path:        "siaran",
		Table:       "siaran",
		Fields: []Field{
			{Name: "youtube_id", Type: Text, Required: true, MaxLen: 20, Pattern: `^[A-Za-z0-9_-]{11}$`,
				Label: "Video YouTube", Input: InputYouTube, Help: "Tempel link video YouTube"},
			{Name: "judul", Type: Text, Required: true, MaxLen: 300, Label: "Judul"},
			{Name: "kategori", Type: Text, Required: true, OneOf: []string{"umum", "anak", "remaja", "sekolah_minggu"},
				Label: "Kategori", Input: InputSelect},
			{Name: "tanggal", Type: Timestamp, Required: true, Label: "Tanggal ibadah", Input: InputDate},
			{Name: "deskripsi", Type: Text, Label: "Deskripsi", Input: InputTextarea},
			{Name: "thumbnail", Type: Text, URL: true, MaxLen: 1000, Label: "Thumbnail khusus", Input: InputURL,
				Help: "Kosongkan untuk memakai thumbnail YouTube"},
		},
		OrderBy: "tanggal DESC, created_at DESC",
		Filters: []string{"kategori"},
	},
	{
		Label:      "Agenda",
		Group:      GroupIbadah,
		Columns:    []string{"judul", "tanggal", "tempat"},
		TitleField: "judul",
		Path:       "agenda",
		Table:      "agenda",
		Fields: []Field{
			{Name: "judul", Type: Text, Required: true, MaxLen: 200, Label: "Nama kegiatan"},
			{Name: "tanggal", Type: Timestamp, Required: true, Label: "Waktu", Input: InputDateTime},
			{Name: "tempat", Type: Text, MaxLen: 300, Label: "Tempat"},
			{Name: "deskripsi", Type: Text, Label: "Keterangan", Input: InputTextarea},
		},
		OrderBy: "tanggal ASC",
	},

	// ── Jemaat ─────────────────────────────────────────────────────
	{
		Label:       "Banner Beranda",
		Group:       GroupJemaat,
		Description: "Gambar geser di beranda aplikasi. Rasio 16:9.",
		Columns:     []string{"image_url", "judul", "urutan", "is_active"},
		TitleField:  "judul",
		Path:        "banners",
		Table:       "banner_slide",
		Fields: []Field{
			{Name: "image_url", Type: Text, Required: true, URL: true, MaxLen: 1000,
				Label: "Gambar", Input: InputImage, Upload: "banners"},
			{Name: "judul", Type: Text, MaxLen: 200, Label: "Judul"},
			{Name: "link_url", Type: Text, URL: true, MaxLen: 1000, Label: "Link saat diketuk", Input: InputURL},
			urutanField,
			{Name: "is_active", Type: Bool, NotNull: true, Label: "Tampilkan", Input: InputSwitch},
		},
		OrderBy:     "urutan ASC, created_at ASC",
		PublicWhere: "is_active",
	},
	{
		Label:      "Galeri",
		Group:      GroupJemaat,
		Columns:    []string{"foto_url", "judul", "tahun", "komisi"},
		TitleField: "judul",
		Path:       "galeri",
		Table:      "galeri",
		Fields: []Field{
			{Name: "foto_url", Type: Text, Required: true, URL: true, MaxLen: 1000,
				Label: "Foto", Input: InputImage, Upload: "galeri"},
			{Name: "judul", Type: Text, Required: true, MaxLen: 200, Label: "Judul"},
			{Name: "tahun", Type: Int, Required: true, Min: intPtr(1900), Max: intPtr(2200), Label: "Tahun"},
			{Name: "komisi", Type: Text, MaxLen: 200, Label: "Komisi / kegiatan"},
			{Name: "deskripsi", Type: Text, Label: "Keterangan", Input: InputTextarea},
		},
		OrderBy:  "tahun DESC, created_at DESC",
		Filters:  []string{"tahun"},
		Distinct: []string{"tahun"},
	},
	{
		Label:       "Pengumuman",
		Group:       GroupJemaat,
		Description: "Tampil di menu Notifikasi aplikasi.",
		Columns:     []string{"judul", "pesan", "is_active"},
		TitleField:  "judul",
		Path:        "notifikasi",
		Table:       "notifikasi",
		Fields: []Field{
			{Name: "judul", Type: Text, Required: true, MaxLen: 200, Label: "Judul"},
			{Name: "pesan", Type: Text, Required: true, MaxLen: 2000, Label: "Pesan", Input: InputTextarea},
			{Name: "is_active", Type: Bool, NotNull: true, Label: "Tampilkan", Input: InputSwitch},
		},
		OrderBy:     "created_at DESC",
		PublicWhere: "is_active",
	},
	{
		Label:      "E-Perpustakaan",
		Group:      GroupJemaat,
		Columns:    []string{"cover_url", "judul", "penulis", "tahun"},
		TitleField: "judul",
		Path:       "eperpus",
		Table:      "eperpus",
		Fields: []Field{
			{Name: "judul", Type: Text, Required: true, MaxLen: 300, Label: "Judul buku"},
			{Name: "penulis", Type: Text, MaxLen: 200, Label: "Penulis"},
			{Name: "tahun", Type: Int, Min: intPtr(1500), Max: intPtr(2200), Label: "Tahun terbit"},
			{Name: "file_url", Type: Text, Required: true, URL: true, MaxLen: 1000,
				Label: "File PDF", Input: InputPDF, Upload: "eperpus"},
			{Name: "cover_url", Type: Text, URL: true, MaxLen: 1000, Label: "Sampul", Input: InputImage, Upload: "eperpus-cover"},
			{Name: "deskripsi", Type: Text, Label: "Sinopsis", Input: InputTextarea},
		},
		OrderBy: "created_at DESC",
	},
	{
		Label:       "Inspirasi",
		Group:       GroupJemaat,
		Description: "Tantangan di roda putar menu Inspirasi.",
		Columns:     []string{"teks", "kategori", "warna"},
		TitleField:  "teks",
		Path:        "inspirasi",
		Table:       "inspirasi",
		Fields: []Field{
			{Name: "kategori", Type: Text, Required: true, OneOf: []string{"anak", "dewasa"}, Label: "Untuk", Input: InputSelect},
			{Name: "teks", Type: Text, Required: true, MaxLen: 1000, Label: "Tantangan", Input: InputTextarea},
			{Name: "warna", Type: Text, NotNull: true, MaxLen: 20, Pattern: `^#[0-9A-Fa-f]{6}$`, Label: "Warna", Input: InputColor},
		},
		OrderBy: "created_at ASC",
		Filters: []string{"kategori"},
	},

	// ── Profil Gereja ──────────────────────────────────────────────
	{
		Label:     "Informasi Gereja",
		Group:     GroupProfil,
		Path:      "informasi-gereja",
		Table:     "informasi_gereja",
		Singleton: true,
		Fields: []Field{
			{Name: "nama", Type: Text, MaxLen: 200, Label: "Nama gereja"},
			{Name: "alamat", Type: Text, MaxLen: 500, Label: "Alamat", Input: InputTextarea},
			{Name: "deskripsi", Type: Text, Label: "Sejarah singkat", Input: InputTextarea},
			{Name: "visi", Type: Text, Label: "Visi", Input: InputTextarea},
			{Name: "misi", Type: Text, Label: "Misi", Input: InputTextarea},
			{Name: "telepon", Type: Text, MaxLen: 50, Label: "Telepon"},
			{Name: "email", Type: Text, MaxLen: 200, Label: "Email"},
			{Name: "maps_url", Type: Text, URL: true, MaxLen: 1000, Label: "Link Google Maps", Input: InputURL},
		},
	},
	{
		Label:       "Cover Menu Gereja",
		Group:       GroupProfil,
		Description: "Gambar besar di tiap menu halaman Gereja (rasio 16:9). Menyimpan menu yang sama akan mengganti cover lama.",
		Columns:     []string{"image_url", "key"},
		TitleField:  "key",
		Path:        "gereja-covers",
		Table:       "gereja_covers",
		Fields: []Field{
			{Name: "key", Type: Text, Required: true, Label: "Menu", Input: InputSelect, OneOf: []string{
				"informasi_gereja", "kependetaan", "kemajelisan", "bpm", "perwilayahan", "profil_ruangan",
			}},
			{Name: "image_url", Type: Text, Required: true, URL: true, MaxLen: 1000,
				Label: "Gambar", Input: InputImage, Upload: "gereja-covers"},
		},
		OrderBy:   "key ASC",
		UpsertKey: "key",
	},
	profilResource("kependetaan", "Kependetaan"),
	profilResource("kemajelisan", "Kemajelisan"),
	kelompokResource("bpm", "bpm", "Badan Pembantu Majelis"),
	kelompokResource("perwilayahan", "perwilayahan", "Perwilayahan"),
	{
		Label:      "Profil Ruangan",
		Group:      GroupProfil,
		Columns:    []string{"foto_url", "nama", "kapasitas", "urutan"},
		TitleField: "nama",
		Path:       "profil-ruangan",
		Table:      "profil_ruangan",
		Fields: []Field{
			{Name: "nama", Type: Text, Required: true, MaxLen: 200, Label: "Nama ruangan"},
			{Name: "kapasitas", Type: Int, Min: intPtr(0), Max: intPtr(100000), Label: "Kapasitas (orang)"},
			{Name: "deskripsi", Type: Text, Label: "Keterangan", Input: InputTextarea},
			fotoField,
			urutanField,
		},
		OrderBy: "urutan ASC, created_at ASC",
	},

	// ── Informasi & Pengaturan ─────────────────────────────────────
	{
		Label:      "Hubungi Kami",
		Group:      GroupInformasi,
		Columns:    []string{"nama", "jenis", "nilai", "urutan"},
		TitleField: "nama",
		Path:       "hubungi-kami",
		Table:      "hubungi_kami",
		Fields: []Field{
			{Name: "nama", Type: Text, Required: true, MaxLen: 200, Label: "Nama", Help: "Mis. WhatsApp Sekretariat"},
			{Name: "jenis", Type: Text, Required: true, OneOf: []string{"whatsapp", "email", "instagram", "facebook", "youtube"},
				Label: "Jenis", Input: InputSelect},
			{Name: "nilai", Type: Text, Required: true, MaxLen: 1000, Label: "Nomor / alamat",
				Help: "WhatsApp: 628xxxx · Email: nama@domain · Instagram: @akun"},
			{Name: "ikon", Type: Text, MaxLen: 100, Label: "Ikon (opsional)"},
			urutanField,
		},
		OrderBy: "urutan ASC, created_at ASC",
	},
	{
		Label:      "FAQ",
		Group:      GroupInformasi,
		Columns:    []string{"pertanyaan", "urutan"},
		TitleField: "pertanyaan",
		Path:       "faq",
		Table:      "faq",
		Fields: []Field{
			{Name: "pertanyaan", Type: Text, Required: true, MaxLen: 500, Label: "Pertanyaan"},
			{Name: "jawaban", Type: Text, Required: true, Label: "Jawaban", Input: InputTextarea},
			urutanField,
		},
		OrderBy: "urutan ASC, created_at ASC",
	},
	{
		Label:       "Sapaan Harian",
		Group:       GroupInformasi,
		Description: "Ayat dan jam notifikasi sapaan pagi & malam di aplikasi.",
		Path:        "sapaan-config",
		Table:       "sapaan_config",
		Singleton:   true,
		Fields: []Field{
			{Name: "jam_pagi", Type: Int, NotNull: true, Min: intPtr(0), Max: intPtr(23), Label: "Jam pagi"},
			{Name: "menit_pagi", Type: Int, NotNull: true, Min: intPtr(0), Max: intPtr(59), Label: "Menit pagi"},
			{Name: "ayat_pagi", Type: Text, NotNull: true, MaxLen: 1000, Label: "Ayat pagi", Input: InputTextarea},
			{Name: "jam_malam", Type: Int, NotNull: true, Min: intPtr(0), Max: intPtr(23), Label: "Jam malam"},
			{Name: "menit_malam", Type: Int, NotNull: true, Min: intPtr(0), Max: intPtr(59), Label: "Menit malam"},
			{Name: "ayat_malam", Type: Text, NotNull: true, MaxLen: 1000, Label: "Ayat malam", Input: InputTextarea},
		},
	},
	{
		Label:     "Tentang Aplikasi",
		Group:     GroupInformasi,
		Path:      "tentang-aplikasi",
		Table:     "tentang_aplikasi",
		Singleton: true,
		Fields: []Field{
			{Name: "versi", Type: Text, MaxLen: 50, Label: "Versi"},
			{Name: "deskripsi", Type: Text, Label: "Deskripsi", Input: InputTextarea},
			{Name: "tim_pengembang", Type: Text, Label: "Tim pengembang", Input: InputTextarea},
		},
	},
}

// profilResource: daftar orang dengan jabatan (kependetaan, kemajelisan).
func profilResource(table, label string) Resource {
	return Resource{
		Label:      label,
		Group:      GroupProfil,
		Columns:    []string{"foto_url", "nama", "jabatan", "urutan"},
		TitleField: "nama",
		Path:       table,
		Table:      table,
		Fields: []Field{
			{Name: "nama", Type: Text, Required: true, MaxLen: 200, Label: "Nama"},
			{Name: "jabatan", Type: Text, Required: true, MaxLen: 200, Label: "Jabatan"},
			fotoField,
			{Name: "bio", Type: Text, Label: "Profil singkat", Input: InputTextarea},
			{Name: "komisi", Type: Text, MaxLen: 200, Label: "Komisi"},
			urutanField,
		},
		OrderBy: "urutan ASC, created_at ASC",
	}
}

// kelompokResource: kelompok dengan ketua (BPM, perwilayahan).
func kelompokResource(path, table, label string) Resource {
	return Resource{
		Label:      label,
		Group:      GroupProfil,
		Columns:    []string{"foto_url", "nama", "ketua", "urutan"},
		TitleField: "nama",
		Path:       path,
		Table:      table,
		Fields: []Field{
			{Name: "nama", Type: Text, Required: true, MaxLen: 200, Label: "Nama"},
			{Name: "ketua", Type: Text, MaxLen: 200, Label: "Ketua"},
			{Name: "deskripsi", Type: Text, Label: "Keterangan", Input: InputTextarea},
			fotoField,
			urutanField,
		},
		OrderBy: "urutan ASC, created_at ASC",
	}
}
