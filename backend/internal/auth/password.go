package auth

import (
	"errors"
	"fmt"
	"unicode/utf8"

	"golang.org/x/crypto/bcrypt"
)

// MinPasswordLen adalah panjang minimal password admin.
const MinPasswordLen = 10

// bcrypt hanya memproses 72 byte pertama; tolak yang lebih panjang agar tidak menyesatkan.
const maxPasswordBytes = 72

// dummyHash dipakai saat email tidak ditemukan agar waktu respons tetap sama
// (mencegah penebakan email admin lewat perbedaan waktu).
var dummyHash, _ = bcrypt.GenerateFromPassword([]byte("dummy-password-for-timing"), bcrypt.DefaultCost)

// HashPassword memvalidasi lalu meng-hash password dengan bcrypt.
func HashPassword(password string) (string, error) {
	if utf8.RuneCountInString(password) < MinPasswordLen {
		return "", fmt.Errorf("password minimal %d karakter", MinPasswordLen)
	}
	if len(password) > maxPasswordBytes {
		return "", errors.New("password maksimal 72 byte")
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", fmt.Errorf("hash password: %w", err)
	}
	return string(hash), nil
}

// CheckPassword membandingkan password dengan hash.
func CheckPassword(hash, password string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}
