// Package upload menyimpan file (gambar & PDF) di disk dan menyajikannya kembali.
package upload

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/google/uuid"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/httpx"
)

// Kind adalah jenis file yang diterima sebuah bucket.
type Kind int

// Jenis file.
const (
	Image Kind = iota
	PDF
)

// Batas ukuran per jenis file.
const (
	MaxImageBytes = 5 << 20  // 5 MB (gambar sudah dikompres ~100 KB di aplikasi)
	MaxPDFBytes   = 30 << 20 // 30 MB
)

// Buckets adalah folder penyimpanan yang diizinkan beserta jenis filenya.
var Buckets = map[string]Kind{
	"banners":       Image,
	"gereja-covers": Image,
	"galeri":        Image,
	"profil":        Image,
	"eperpus-cover": Image,
	"dokumen-cover": Image,
	"dokumen":       PDF,
	"eperpus":       PDF,
}

var allowedTypes = map[Kind]map[string]string{ // content-type → ekstensi
	Image: {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"},
	PDF:   {"application/pdf": "pdf"},
}

// Nama file selalu dibuat server: 32 hex + ekstensi. Mencegah path traversal.
var fileNamePattern = regexp.MustCompile(`^[0-9a-f]{32}\.(jpg|png|webp|pdf)$`)

// Storage menyimpan file di bawah root/{bucket}/{nama}.
type Storage struct {
	root    string
	baseURL string // mis. https://api.gkjw.org → URL file: {baseURL}/files/{bucket}/{nama}
}

// NewStorage membuat storage dan memastikan folder bucket tersedia.
func NewStorage(root, baseURL string) (*Storage, error) {
	for bucket := range Buckets {
		if err := os.MkdirAll(filepath.Join(root, bucket), 0o755); err != nil {
			return nil, fmt.Errorf("buat folder %s: %w", bucket, err)
		}
	}
	return &Storage{root: root, baseURL: strings.TrimRight(baseURL, "/")}, nil
}

// Stored adalah hasil penyimpanan file.
type Stored struct {
	URL    string `json:"url"`
	Bucket string `json:"bucket"`
	Name   string `json:"name"`
	Size   int64  `json:"size"`
}

// MaxBytes mengembalikan batas ukuran untuk bucket.
func MaxBytes(bucket string) int64 {
	if Buckets[bucket] == PDF {
		return MaxPDFBytes
	}
	return MaxImageBytes
}

// Save memvalidasi isi file (bukan dari ekstensi/klaim klien) lalu menyimpannya.
func (s *Storage) Save(bucket string, src io.Reader) (Stored, error) {
	kind, ok := Buckets[bucket]
	if !ok {
		return Stored{}, httpx.BadRequest("bucket tidak dikenal")
	}

	br := bufio.NewReaderSize(src, 512)
	head, err := br.Peek(512)
	if err != nil && !errors.Is(err, io.EOF) && !errors.Is(err, bufio.ErrBufferFull) {
		return Stored{}, fmt.Errorf("baca file: %w", err)
	}
	if len(head) == 0 {
		return Stored{}, httpx.BadRequest("file kosong")
	}
	contentType := http.DetectContentType(head)
	ext, ok := allowedTypes[kind][contentType]
	if !ok {
		return Stored{}, &httpx.Error{Code: "unsupported_media_type", Message: "Jenis file tidak didukung: " + contentType}
	}

	name := strings.ReplaceAll(uuid.NewString(), "-", "") + "." + ext
	dir := filepath.Join(s.root, bucket)
	tmp, err := os.CreateTemp(dir, ".upload-*")
	if err != nil {
		return Stored{}, fmt.Errorf("buat file sementara: %w", err)
	}
	defer os.Remove(tmp.Name()) // no-op setelah rename berhasil

	limit := MaxBytes(bucket)
	n, err := io.Copy(tmp, io.LimitReader(br, limit+1))
	if closeErr := tmp.Close(); err == nil {
		err = closeErr
	}
	if err != nil {
		return Stored{}, fmt.Errorf("tulis file: %w", err)
	}
	if n > limit {
		return Stored{}, &httpx.Error{Code: "payload_too_large", Message: fmt.Sprintf("Ukuran file maksimal %d MB", limit>>20)}
	}
	if err := os.Rename(tmp.Name(), filepath.Join(dir, name)); err != nil {
		return Stored{}, fmt.Errorf("simpan file: %w", err)
	}
	return Stored{URL: s.URL(bucket, name), Bucket: bucket, Name: name, Size: n}, nil
}

// Delete menghapus file; mengembalikan httpx.ErrNotFound bila tidak ada.
func (s *Storage) Delete(bucket, name string) error {
	path, err := s.path(bucket, name)
	if err != nil {
		return err
	}
	if err := os.Remove(path); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return httpx.ErrNotFound
		}
		return fmt.Errorf("hapus file: %w", err)
	}
	return nil
}

// Open membuka file untuk disajikan.
func (s *Storage) Open(bucket, name string) (*os.File, error) {
	path, err := s.path(bucket, name)
	if err != nil {
		return nil, err
	}
	f, err := os.Open(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, httpx.ErrNotFound
	}
	return f, err
}

// URL membangun URL publik sebuah file.
func (s *Storage) URL(bucket, name string) string {
	return s.baseURL + "/files/" + bucket + "/" + name
}

func (s *Storage) path(bucket, name string) (string, error) {
	if _, ok := Buckets[bucket]; !ok || !fileNamePattern.MatchString(name) {
		return "", httpx.ErrNotFound
	}
	return filepath.Join(s.root, bucket, name), nil
}
