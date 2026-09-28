package youtube

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestExtractID(t *testing.T) {
	const id = "dQw4w9WgXcQ"
	for _, in := range []string{
		"https://www.youtube.com/watch?v=" + id,
		"https://www.youtube.com/watch?feature=share&v=" + id + "&t=10",
		"https://youtu.be/" + id + "?si=abc",
		"https://www.youtube.com/live/" + id,
		"https://youtube.com/shorts/" + id,
		"https://www.youtube.com/embed/" + id,
		"  " + id + "  ",
	} {
		if got, ok := ExtractID(in); !ok || got != id {
			t.Errorf("ExtractID(%q) = %q, %v", in, got, ok)
		}
	}
	for _, bad := range []string{"", "https://example.com/video", "abc"} {
		if _, ok := ExtractID(bad); ok {
			t.Errorf("ExtractID(%q) should fail", bad)
		}
	}
}

func TestParseDateFromTitle(t *testing.T) {
	cases := map[string]string{
		"Ibadah Minggu 27 April 2025": "2025-04-27",
		"Ibadah 5 Sept 2026 | GKJW":   "2026-09-05",
		"IBADAH 1 DESEMBER 2024":      "2024-12-01",
		"Ibadah 20/04/2025":           "2025-04-20",
		"Ibadah 20-4-2025":            "2025-04-20",
		"Ibadah 31 Februari 2025":     "",
		"Ibadah Paskah":               "",
	}
	for title, want := range cases {
		got := ParseDateFromTitle(title)
		if want == "" {
			if got != nil {
				t.Errorf("%q: expected nil, got %v", title, got)
			}
			continue
		}
		if got == nil || got.Format("2006-01-02") != want {
			t.Errorf("%q: got %v, want %s", title, got, want)
		}
	}
}

func fakeYouTube(t *testing.T, oembedStatus int, page string) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Query().Has("key") {
			t.Error("must not use a Google API key")
		}
		switch r.URL.Path {
		case "/oembed":
			w.WriteHeader(oembedStatus)
			w.Write([]byte(`{"title":"Ibadah Minggu 27 April 2025"}`))
		case "/watch":
			if page == "" {
				w.WriteHeader(http.StatusTooManyRequests)
				return
			}
			w.Write([]byte(page))
		}
	}))
	t.Cleanup(srv.Close)
	return srv
}

const watchPage = `<html><meta name="title" content="Ibadah Remaja &amp; Pemuda">
<meta itemprop="datePublished" content="2025-04-28T01:00:00-07:00">
<script>var ytInitialPlayerResponse = {"videoDetails":{"shortDescription":"Pelayan firman: Pdt. A\nTema: \"Kasih\""}};</script></html>`

func TestFetch_CombinesSourcesAndPrefersTitleDate(t *testing.T) {
	srv := fakeYouTube(t, http.StatusOK, watchPage)
	meta, err := Client{BaseURL: srv.URL}.Fetch(context.Background(), "dQw4w9WgXcQ")
	if err != nil {
		t.Fatal(err)
	}
	if meta.Title != "Ibadah Minggu 27 April 2025" {
		t.Errorf("title = %q", meta.Title)
	}
	if meta.Description != "Pelayan firman: Pdt. A\nTema: \"Kasih\"" {
		t.Errorf("description = %q", meta.Description)
	}
	if meta.Date == nil || meta.Date.Format("2006-01-02") != "2025-04-27" {
		t.Errorf("date = %v (tanggal di judul harus diutamakan)", meta.Date)
	}
	if !strings.Contains(meta.Thumbnail, "dQw4w9WgXcQ") {
		t.Errorf("thumbnail = %q", meta.Thumbnail)
	}
}

func TestFetch_FallsBackToPageTitleAndUploadDate(t *testing.T) {
	srv := fakeYouTube(t, http.StatusNotFound, watchPage)
	meta, err := Client{BaseURL: srv.URL}.Fetch(context.Background(), "dQw4w9WgXcQ")
	if err != nil {
		t.Fatal(err)
	}
	if meta.Title != "Ibadah Remaja & Pemuda" {
		t.Errorf("title = %q", meta.Title)
	}
	want := time.Date(2025, 4, 28, 8, 0, 0, 0, time.UTC)
	if meta.Date == nil || !meta.Date.Equal(want) {
		t.Errorf("date = %v, want %v", meta.Date, want)
	}
}

func TestFetch_TitleOnlyWhenPageBlocked(t *testing.T) {
	srv := fakeYouTube(t, http.StatusOK, "")
	meta, err := Client{BaseURL: srv.URL}.Fetch(context.Background(), "dQw4w9WgXcQ")
	if err != nil || meta.Title == "" || meta.Description != "" {
		t.Errorf("meta = %+v err = %v", meta, err)
	}
}

func TestFetch_ErrorWhenNothingWorks(t *testing.T) {
	srv := fakeYouTube(t, http.StatusNotFound, "")
	if _, err := (Client{BaseURL: srv.URL}).Fetch(context.Background(), "dQw4w9WgXcQ"); err == nil {
		t.Error("expected error")
	}
}
