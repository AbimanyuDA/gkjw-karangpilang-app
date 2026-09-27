package resource

import (
	"encoding/json"
	"fmt"
	"slices"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"
)

// Field yang dikelola server; diabaikan bila dikirim klien.
var serverManaged = map[string]bool{"id": true, "created_at": true, "updated_at": true}

// jakarta dipakai untuk timestamp tanpa zona waktu (mis. dari DateTime.toIso8601String() Dart).
var jakarta = time.FixedZone("WIB", 7*60*60)

// Mode menentukan aturan validasi.
type Mode int

// Mode validasi.
const (
	Create Mode = iota // field Required wajib ada
	Update             // hanya field yang dikirim yang diubah
)

// Validate memeriksa input terhadap spec dan mengembalikan nilai yang sudah
// dikonversi ke tipe Go. Kesalahan dikembalikan per field.
func (r Resource) Validate(input map[string]any, mode Mode) (map[string]any, map[string]string) {
	out := make(map[string]any, len(input))
	errs := map[string]string{}

	for key, raw := range input {
		if serverManaged[key] {
			continue
		}
		f, ok := r.field(key)
		if !ok {
			errs[key] = "field tidak dikenal"
			continue
		}
		val, msg := f.convert(raw)
		if msg != "" {
			errs[key] = msg
			continue
		}
		out[key] = val
	}

	if mode == Create {
		for _, f := range r.Fields {
			if _, present := input[f.Name]; f.Required && !present {
				errs[f.Name] = "wajib diisi"
			}
		}
	}
	if len(out) == 0 && len(errs) == 0 {
		errs["_"] = "tidak ada data yang dikirim"
	}
	if len(errs) > 0 {
		return nil, errs
	}
	return out, nil
}

func (f Field) convert(raw any) (any, string) {
	if raw == nil {
		if f.Required || f.NotNull {
			return nil, "tidak boleh kosong"
		}
		return nil, ""
	}
	switch f.Type {
	case Text:
		return f.convertText(raw)
	case Int:
		return f.convertInt(raw)
	case Bool:
		b, ok := raw.(bool)
		if !ok {
			return nil, "harus berupa true/false"
		}
		return b, ""
	case Timestamp:
		return convertTimestamp(raw)
	default:
		return nil, "tipe field tidak didukung"
	}
}

func (f Field) convertText(raw any) (any, string) {
	s, ok := raw.(string)
	if !ok {
		return nil, "harus berupa teks"
	}
	if f.Required && strings.TrimSpace(s) == "" {
		return nil, "tidak boleh kosong"
	}
	maxLen := f.MaxLen
	if maxLen == 0 {
		maxLen = defaultMaxLen
	}
	if utf8.RuneCountInString(s) > maxLen {
		return nil, fmt.Sprintf("maksimal %d karakter", maxLen)
	}
	if f.URL && s != "" && !strings.HasPrefix(s, "https://") && !strings.HasPrefix(s, "http://") {
		return nil, "harus berupa URL http(s)"
	}
	if len(f.OneOf) > 0 && !slices.Contains(f.OneOf, s) {
		return nil, "harus salah satu dari: " + strings.Join(f.OneOf, ", ")
	}
	return s, ""
}

func (f Field) convertInt(raw any) (any, string) {
	var n int64
	switch v := raw.(type) {
	case json.Number:
		parsed, err := v.Int64()
		if err != nil {
			return nil, "harus berupa bilangan bulat"
		}
		n = parsed
	case string: // dipakai untuk query param
		parsed, err := strconv.ParseInt(v, 10, 64)
		if err != nil {
			return nil, "harus berupa bilangan bulat"
		}
		n = parsed
	default:
		return nil, "harus berupa bilangan bulat"
	}
	if f.Min != nil && n < int64(*f.Min) {
		return nil, fmt.Sprintf("minimal %d", *f.Min)
	}
	if f.Max != nil && n > int64(*f.Max) {
		return nil, fmt.Sprintf("maksimal %d", *f.Max)
	}
	return n, ""
}

func convertTimestamp(raw any) (any, string) {
	s, ok := raw.(string)
	if !ok {
		return nil, "harus berupa tanggal ISO-8601"
	}
	if t, err := time.Parse(time.RFC3339Nano, s); err == nil {
		return t, ""
	}
	for _, layout := range []string{"2006-01-02T15:04:05.999999999", "2006-01-02T15:04:05", "2006-01-02"} {
		if t, err := time.ParseInLocation(layout, s, jakarta); err == nil {
			return t, ""
		}
	}
	return nil, "harus berupa tanggal ISO-8601"
}
