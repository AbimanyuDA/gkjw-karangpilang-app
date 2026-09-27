// Package auth menangani login admin: hash password, token JWT, dan middleware.
package auth

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const issuer = "gkjw-api"

// Claims adalah isi token admin.
type Claims struct {
	Email string `json:"email"`
	jwt.RegisteredClaims
}

// Tokens menerbitkan dan memverifikasi JWT HS256.
type Tokens struct {
	secret []byte
	ttl    time.Duration
	now    func() time.Time
}

// NewTokens membuat penerbit token.
func NewTokens(secret []byte, ttl time.Duration) *Tokens {
	return &Tokens{secret: secret, ttl: ttl, now: time.Now}
}

// Issue membuat token untuk admin.
func (t *Tokens) Issue(adminID, email string) (string, time.Time, error) {
	now := t.now()
	exp := now.Add(t.ttl)
	claims := Claims{
		Email: email,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   adminID,
			Issuer:    issuer,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(exp),
		},
	}
	signed, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(t.secret)
	if err != nil {
		return "", time.Time{}, fmt.Errorf("tanda tangani token: %w", err)
	}
	return signed, exp, nil
}

// Verify memeriksa tanda tangan, algoritma, issuer, dan masa berlaku token.
func (t *Tokens) Verify(raw string) (*Claims, error) {
	claims := &Claims{}
	_, err := jwt.ParseWithClaims(raw, claims,
		func(*jwt.Token) (any, error) { return t.secret, nil },
		jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}),
		jwt.WithIssuer(issuer),
		jwt.WithExpirationRequired(),
		jwt.WithTimeFunc(t.now),
	)
	if err != nil {
		return nil, fmt.Errorf("token tidak valid: %w", err)
	}
	if claims.Subject == "" {
		return nil, errors.New("token tidak valid: subject kosong")
	}
	return claims, nil
}
