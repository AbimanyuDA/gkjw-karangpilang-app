// Package httpx berisi helper HTTP bersama: amplop respons JSON dan decoding body.
package httpx

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
)

// MaxJSONBody membatasi ukuran body JSON agar tidak bisa dipakai membanjiri memori.
const MaxJSONBody = 1 << 20 // 1 MB

// Meta berisi informasi paginasi untuk respons daftar.
type Meta struct {
	Total  int `json:"total"`
	Limit  int `json:"limit"`
	Offset int `json:"offset"`
}

// Envelope adalah bentuk standar semua respons API.
type Envelope struct {
	Success bool   `json:"success"`
	Data    any    `json:"data"`
	Error   *Error `json:"error"`
	Meta    *Meta  `json:"meta,omitempty"`
}

// Error adalah pesan kesalahan yang aman ditampilkan ke klien.
type Error struct {
	Code    string            `json:"code"`
	Message string            `json:"message"`
	Fields  map[string]string `json:"fields,omitempty"`
}

func (e *Error) Error() string { return e.Code + ": " + e.Message }

// Kesalahan umum yang dipakai lintas handler.
var (
	ErrNotFound     = &Error{Code: "not_found", Message: "Data tidak ditemukan"}
	ErrUnauthorized = &Error{Code: "unauthorized", Message: "Silakan login terlebih dahulu"}
	ErrBadJSON      = &Error{Code: "bad_request", Message: "Format JSON tidak valid"}
)

// Validation membuat error validasi per field.
func Validation(fields map[string]string) *Error {
	return &Error{Code: "validation_error", Message: "Data tidak valid", Fields: fields}
}

// BadRequest membuat error 400 dengan pesan tertentu.
func BadRequest(msg string) *Error {
	return &Error{Code: "bad_request", Message: msg}
}

// OK menulis respons sukses.
func OK(w http.ResponseWriter, status int, data any, meta *Meta) {
	write(w, status, Envelope{Success: true, Data: data, Meta: meta})
}

// Fail menulis respons gagal. Error selain *Error dicatat di log dan
// dikembalikan sebagai 500 generik agar detail internal tidak bocor.
func Fail(w http.ResponseWriter, r *http.Request, err error) {
	var apiErr *Error
	if errors.As(err, &apiErr) {
		write(w, statusFor(apiErr.Code), Envelope{Error: apiErr})
		return
	}
	slog.ErrorContext(r.Context(), "request failed", "method", r.Method, "path", r.URL.Path, "err", err)
	write(w, http.StatusInternalServerError, Envelope{
		Error: &Error{Code: "internal_error", Message: "Terjadi kesalahan pada server"},
	})
}

// DecodeJSON membaca body JSON ke dst dengan batas ukuran dan menolak field tak dikenal.
func DecodeJSON(r *http.Request, dst any) error {
	if ct := r.Header.Get("Content-Type"); ct != "" && !strings.HasPrefix(ct, "application/json") {
		return BadRequest("Content-Type harus application/json")
	}
	dec := json.NewDecoder(io.LimitReader(r.Body, MaxJSONBody))
	dec.UseNumber()
	if err := dec.Decode(dst); err != nil {
		return ErrBadJSON
	}
	if dec.More() {
		return ErrBadJSON
	}
	return nil
}

func statusFor(code string) int {
	switch code {
	case "not_found":
		return http.StatusNotFound
	case "unauthorized":
		return http.StatusUnauthorized
	case "validation_error", "bad_request":
		return http.StatusBadRequest
	case "payload_too_large":
		return http.StatusRequestEntityTooLarge
	case "unsupported_media_type":
		return http.StatusUnsupportedMediaType
	case "conflict":
		return http.StatusConflict
	default:
		return http.StatusInternalServerError
	}
}

func write(w http.ResponseWriter, status int, body Envelope) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		slog.Error("encode response", "err", fmt.Sprint(err))
	}
}
