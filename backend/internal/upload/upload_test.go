package upload

import (
	"bytes"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
)

var (
	pngBytes = append([]byte("\x89PNG\r\n\x1a\n"), bytes.Repeat([]byte{0}, 64)...)
	pdfBytes = []byte("%PDF-1.4\n%fake pdf content\n")
)

func newTestServer(t *testing.T) (*Storage, http.Handler) {
	t.Helper()
	st, err := NewStorage(t.TempDir(), "https://api.test/")
	if err != nil {
		t.Fatal(err)
	}
	h := NewHandler(st)
	r := chi.NewRouter()
	r.Post("/uploads", h.Upload)
	r.Delete("/uploads/{bucket}/{name}", h.Delete)
	r.Get("/files/{bucket}/{name}", h.Serve)
	return st, r
}

func multipartBody(t *testing.T, field string, content []byte) (*bytes.Buffer, string) {
	t.Helper()
	var buf bytes.Buffer
	mw := multipart.NewWriter(&buf)
	fw, err := mw.CreateFormFile(field, "anything.exe") // nama dari klien diabaikan
	if err != nil {
		t.Fatal(err)
	}
	fw.Write(content)
	mw.Close()
	return &buf, mw.FormDataContentType()
}

func upload(t *testing.T, h http.Handler, bucket string, content []byte) *httptest.ResponseRecorder {
	t.Helper()
	body, ct := multipartBody(t, "file", content)
	req := httptest.NewRequest("POST", "/uploads?bucket="+bucket, body)
	req.Header.Set("Content-Type", ct)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestUpload_SaveServeDelete(t *testing.T) {
	_, h := newTestServer(t)
	rec := upload(t, h, "banners", pngBytes)
	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d body = %s", rec.Code, rec.Body)
	}
	var resp struct{ Data Stored }
	json.Unmarshal(rec.Body.Bytes(), &resp)
	if !strings.HasPrefix(resp.Data.URL, "https://api.test/files/banners/") || !strings.HasSuffix(resp.Data.Name, ".png") {
		t.Fatalf("stored = %+v", resp.Data)
	}

	get := httptest.NewRecorder()
	h.ServeHTTP(get, httptest.NewRequest("GET", "/files/banners/"+resp.Data.Name, nil))
	if get.Code != http.StatusOK || !bytes.Equal(get.Body.Bytes(), pngBytes) {
		t.Fatalf("serve status = %d", get.Code)
	}
	if !strings.Contains(get.Header().Get("Cache-Control"), "immutable") {
		t.Error("files must be served with immutable cache header")
	}

	del := httptest.NewRecorder()
	h.ServeHTTP(del, httptest.NewRequest("DELETE", "/uploads/banners/"+resp.Data.Name, nil))
	if del.Code != http.StatusOK {
		t.Fatalf("delete status = %d", del.Code)
	}
	again := httptest.NewRecorder()
	h.ServeHTTP(again, httptest.NewRequest("GET", "/files/banners/"+resp.Data.Name, nil))
	if again.Code != http.StatusNotFound {
		t.Errorf("after delete status = %d", again.Code)
	}
}

func TestUpload_Rejections(t *testing.T) {
	_, h := newTestServer(t)
	tests := []struct {
		name    string
		bucket  string
		content []byte
		want    int
	}{
		{"unknown bucket", "etc", pngBytes, http.StatusBadRequest},
		{"pdf into image bucket", "banners", pdfBytes, http.StatusUnsupportedMediaType},
		{"image into pdf bucket", "dokumen", pngBytes, http.StatusUnsupportedMediaType},
		{"html disguised", "galeri", []byte("<html><script>alert(1)</script></html>"), http.StatusUnsupportedMediaType},
		{"empty file", "galeri", nil, http.StatusBadRequest},
		{"too large", "banners", append(pngBytes, bytes.Repeat([]byte{0}, MaxImageBytes)...), http.StatusRequestEntityTooLarge},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rec := upload(t, h, tt.bucket, tt.content)
			if rec.Code != tt.want {
				t.Errorf("status = %d, want %d (%s)", rec.Code, tt.want, rec.Body)
			}
		})
	}
}

func TestUpload_PDFAccepted(t *testing.T) {
	_, h := newTestServer(t)
	if rec := upload(t, h, "dokumen", pdfBytes); rec.Code != http.StatusCreated {
		t.Errorf("status = %d body = %s", rec.Code, rec.Body)
	}
}

func TestUpload_MissingFileField(t *testing.T) {
	_, h := newTestServer(t)
	body, ct := multipartBody(t, "other", pngBytes)
	req := httptest.NewRequest("POST", "/uploads?bucket=banners", body)
	req.Header.Set("Content-Type", ct)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Errorf("status = %d", rec.Code)
	}
}

func TestPathTraversalBlocked(t *testing.T) {
	st, h := newTestServer(t)
	for _, name := range []string{"..%2F..%2Fetc%2Fpasswd", ".upload-123", "ABC.png", "x.png"} {
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, httptest.NewRequest("GET", "/files/banners/"+name, nil))
		if rec.Code != http.StatusNotFound {
			t.Errorf("%s: status = %d", name, rec.Code)
		}
	}
	if err := st.Delete("../..", "passwd"); err == nil {
		t.Error("delete outside bucket must fail")
	}
	if _, err := st.Save("banners", io.MultiReader()); err == nil {
		t.Error("empty reader must fail")
	}
}
