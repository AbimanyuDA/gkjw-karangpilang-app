// Package legacy memindahkan data lama dari Supabase & Firestore ke PostgreSQL baru.
// Dipakai sekali saat migrasi: `api migrate-legacy` (lihat docs/MIGRASI-DATA.md).
package legacy

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
)

// maxResponseBytes membatasi ukuran respons JSON dari sumber lama.
const maxResponseBytes = 50 << 20

// SupabaseSource membaca tabel lewat REST API Supabase (PostgREST) memakai anon key.
type SupabaseSource struct {
	BaseURL string // https://xxxx.supabase.co
	AnonKey string
	Client  *http.Client
}

// Fetch mengambil semua baris sebuah tabel.
func (s SupabaseSource) Fetch(ctx context.Context, table string) ([]map[string]any, error) {
	endpoint := strings.TrimRight(s.BaseURL, "/") + "/rest/v1/" + url.PathEscape(table) + "?select=*"
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("apikey", s.AnonKey)
	req.Header.Set("Authorization", "Bearer "+s.AnonKey)

	var rows []map[string]any
	if err := getJSON(s.Client, req, &rows); err != nil {
		return nil, fmt.Errorf("supabase %s: %w", table, err)
	}
	return rows, nil
}

// FirestoreSource membaca koleksi lewat REST API Firestore memakai API key publik.
type FirestoreSource struct {
	ProjectID string
	APIKey    string
	BaseURL   string // default https://firestore.googleapis.com (bisa diganti saat test)
	Client    *http.Client
}

// Doc adalah satu dokumen Firestore yang sudah diubah ke nilai Go biasa.
type Doc struct {
	ID     string
	Fields map[string]any
}

// Fetch mengambil semua dokumen sebuah koleksi (mengikuti pagination).
func (f FirestoreSource) Fetch(ctx context.Context, collection string) ([]Doc, error) {
	base := f.BaseURL
	if base == "" {
		base = "https://firestore.googleapis.com"
	}
	var docs []Doc
	pageToken := ""
	for {
		q := url.Values{"pageSize": {"300"}, "key": {f.APIKey}}
		if pageToken != "" {
			q.Set("pageToken", pageToken)
		}
		endpoint := fmt.Sprintf("%s/v1/projects/%s/databases/(default)/documents/%s?%s",
			strings.TrimRight(base, "/"), url.PathEscape(f.ProjectID), url.PathEscape(collection), q.Encode())
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
		if err != nil {
			return nil, err
		}

		var page struct {
			Documents []struct {
				Name   string                     `json:"name"`
				Fields map[string]json.RawMessage `json:"fields"`
			} `json:"documents"`
			NextPageToken string `json:"nextPageToken"`
		}
		if err := getJSON(f.Client, req, &page); err != nil {
			return nil, fmt.Errorf("firestore %s: %w", collection, err)
		}
		for _, d := range page.Documents {
			fields := make(map[string]any, len(d.Fields))
			for k, raw := range d.Fields {
				v, err := decodeFirestoreValue(raw)
				if err != nil {
					return nil, fmt.Errorf("firestore %s/%s field %s: %w", collection, d.Name, k, err)
				}
				fields[k] = v
			}
			docs = append(docs, Doc{ID: d.Name[strings.LastIndex(d.Name, "/")+1:], Fields: fields})
		}
		if page.NextPageToken == "" {
			return docs, nil
		}
		pageToken = page.NextPageToken
	}
}

// decodeFirestoreValue mengubah nilai bertipe Firestore ({"stringValue": "x"}) menjadi
// nilai yang dipahami resource.Validate (string, json.Number, bool, nil).
func decodeFirestoreValue(raw json.RawMessage) (any, error) {
	var v struct {
		String    *string          `json:"stringValue"`
		Integer   *string          `json:"integerValue"`
		Double    *json.Number     `json:"doubleValue"`
		Boolean   *bool            `json:"booleanValue"`
		Timestamp *string          `json:"timestampValue"`
		Null      *json.RawMessage `json:"nullValue"`
	}
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.UseNumber()
	if err := dec.Decode(&v); err != nil {
		return nil, err
	}
	switch {
	case v.String != nil:
		return *v.String, nil
	case v.Integer != nil:
		return json.Number(*v.Integer), nil
	case v.Double != nil:
		return *v.Double, nil
	case v.Boolean != nil:
		return *v.Boolean, nil
	case v.Timestamp != nil:
		return *v.Timestamp, nil
	case v.Null != nil:
		return nil, nil
	default:
		return nil, nil // map/array/reference tidak dipakai aplikasi lama
	}
}

func getJSON(client *http.Client, req *http.Request, dst any) error {
	if client == nil {
		client = http.DefaultClient
	}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, maxResponseBytes))
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("status %d: %s", resp.StatusCode, truncate(string(body), 300))
	}
	dec := json.NewDecoder(bytes.NewReader(body))
	dec.UseNumber()
	return dec.Decode(dst)
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "..."
}
