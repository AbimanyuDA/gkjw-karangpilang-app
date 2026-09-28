// Command api menjalankan backend GKJW Karangpilang.
//
// Pemakaian:
//
//	api                         jalankan server (migrasi otomatis saat start)
//	api migrate                 jalankan migrasi saja lalu keluar
//	api create-admin -email X   buat admin / ganti password (password dari
//	                            env ADMIN_PASSWORD atau stdin)
//	api migrate-legacy [-dry-run]
//	                            salin data lama Supabase + Firestore (sekali saja)
package main

import (
	"bufio"
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/auth"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/config"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/database"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/legacy"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/resource"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/server"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/upload"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/youtube"
)

func main() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, os.Args[1:]); err != nil {
		slog.Error("fatal", "err", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string) error {
	// Dipakai HEALTHCHECK Docker; image distroless tidak punya curl/wget.
	if len(args) > 0 && args[0] == "healthcheck" {
		return healthcheck(ctx)
	}

	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("konfigurasi: %w", err)
	}

	pool, err := database.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	if err := database.Migrate(ctx, pool); err != nil {
		return err
	}

	cmd := "serve"
	if len(args) > 0 {
		cmd = args[0]
	}
	switch cmd {
	case "serve":
		return serve(ctx, cfg, pool)
	case "migrate":
		slog.Info("migrasi selesai")
		return nil
	case "create-admin":
		return createAdmin(ctx, auth.NewPgAdminStore(pool), args[1:], os.Stdin)
	case "migrate-legacy":
		return migrateLegacy(ctx, cfg, pool, args[1:])
	default:
		return fmt.Errorf("perintah tidak dikenal: %q", cmd)
	}
}

func serve(ctx context.Context, cfg config.Config, pool *pgxpool.Pool) error {
	storage, err := upload.NewStorage(cfg.UploadDir, cfg.PublicBaseURL)
	if err != nil {
		return err
	}

	router := server.NewRouter(server.Deps{
		DB:             pool,
		Repo:           resource.NewPgStore(pool),
		Auth:           auth.NewHandler(auth.NewPgAdminStore(pool), auth.NewTokens(cfg.JWTSecret, cfg.JWTTTL)),
		Uploads:        upload.NewHandler(storage),
		YouTube:        youtube.Client{HTTP: &http.Client{Timeout: 15 * time.Second}},
		AllowedOrigins: cfg.CORSAllowedOrigins,
		TrustProxy:     cfg.TrustProxy,
	})

	srv := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           router,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       5 * time.Minute, // upload PDF dari jaringan lambat
		WriteTimeout:      5 * time.Minute, // unduh PDF ke jaringan lambat
		IdleTimeout:       2 * time.Minute,
	}

	errCh := make(chan error, 1)
	go func() {
		slog.Info("server berjalan", "port", cfg.Port)
		errCh <- srv.ListenAndServe()
	}()

	select {
	case err := <-errCh:
		if !errors.Is(err, http.ErrServerClosed) {
			return fmt.Errorf("server berhenti: %w", err)
		}
		return nil
	case <-ctx.Done():
		slog.Info("mematikan server...")
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
		defer cancel()
		if err := srv.Shutdown(shutdownCtx); err != nil {
			return fmt.Errorf("shutdown: %w", err)
		}
		return nil
	}
}

func healthcheck(ctx context.Context) error {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://127.0.0.1:"+port+"/healthz", nil)
	if err != nil {
		return err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("healthcheck: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("healthcheck: status %d", resp.StatusCode)
	}
	return nil
}

func migrateLegacy(ctx context.Context, cfg config.Config, pool *pgxpool.Pool, args []string) error {
	fs := flag.NewFlagSet("migrate-legacy", flag.ContinueOnError)
	dryRun := fs.Bool("dry-run", false, "baca & validasi saja, tanpa menulis")
	if err := fs.Parse(args); err != nil {
		return err
	}

	env := map[string]string{}
	for _, key := range []string{"LEGACY_SUPABASE_URL", "LEGACY_SUPABASE_ANON_KEY", "LEGACY_FIREBASE_PROJECT_ID", "LEGACY_FIREBASE_API_KEY"} {
		env[key] = os.Getenv(key)
		if env[key] == "" {
			return fmt.Errorf("env %s wajib diisi (lihat docs/MIGRASI-DATA.md)", key)
		}
	}

	storage, err := upload.NewStorage(cfg.UploadDir, cfg.PublicBaseURL)
	if err != nil {
		return err
	}
	httpClient := &http.Client{Timeout: 2 * time.Minute}
	m := &legacy.Migrator{
		Pool:      pool,
		Supabase:  legacy.SupabaseSource{BaseURL: env["LEGACY_SUPABASE_URL"], AnonKey: env["LEGACY_SUPABASE_ANON_KEY"], Client: httpClient},
		Firestore: legacy.FirestoreSource{ProjectID: env["LEGACY_FIREBASE_PROJECT_ID"], APIKey: env["LEGACY_FIREBASE_API_KEY"], Client: httpClient},
		Files:     storage,
		HTTP:      httpClient,
		DryRun:    *dryRun,
	}
	reports, err := m.Run(ctx)
	for _, r := range reports {
		fmt.Printf("%-18s %-28s dibaca=%-4d diimpor=%-4d dilewati=%-3d %s\n",
			r.Target, r.Source, r.Read, r.Imported, len(r.Skipped), r.Note)
		for _, reason := range r.Skipped {
			fmt.Printf("    - %s\n", reason)
		}
	}
	if *dryRun {
		fmt.Println("DRY RUN: tidak ada data yang ditulis.")
	}
	return err
}

type adminUpserter interface {
	Upsert(ctx context.Context, email, passwordHash string) error
}

func createAdmin(ctx context.Context, store adminUpserter, args []string, stdin io.Reader) error {
	fs := flag.NewFlagSet("create-admin", flag.ContinueOnError)
	email := fs.String("email", "", "email admin")
	if err := fs.Parse(args); err != nil {
		return err
	}
	if !strings.Contains(*email, "@") {
		return errors.New("-email wajib diisi dengan alamat email yang valid")
	}

	password := os.Getenv("ADMIN_PASSWORD")
	if password == "" {
		fmt.Fprint(os.Stderr, "Password admin (min. 10 karakter): ")
		line, err := bufio.NewReader(stdin).ReadString('\n')
		if err != nil && !errors.Is(err, io.EOF) {
			return fmt.Errorf("baca password: %w", err)
		}
		password = strings.TrimRight(line, "\r\n")
	}

	hash, err := auth.HashPassword(password)
	if err != nil {
		return err
	}
	if err := store.Upsert(ctx, *email, hash); err != nil {
		return err
	}
	slog.Info("admin disimpan", "email", auth.NormalizeEmail(*email))
	return nil
}
