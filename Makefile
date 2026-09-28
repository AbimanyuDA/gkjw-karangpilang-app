# Perintah sehari-hari. Jalankan dari root repo:  make <target>
DEV_COMPOSE = docker compose -f deploy/docker-compose.dev.yml
TEST_DB     = postgres://postgres:test@localhost:55432/gkjw_test?sslmode=disable

.PHONY: help dev dev-down dev-logs dev-admin backend-test test-integration app-run app-test app-e2e app-build-apk admin-dev admin-test admin-build

help: ## Tampilkan daftar perintah
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'

# ── Backend lokal ─────────────────────────────────────────────
dev: ## Jalankan PostgreSQL + API di http://localhost:8080
	$(DEV_COMPOSE) up -d --build

dev-down: ## Matikan stack lokal
	$(DEV_COMPOSE) down

dev-logs: ## Lihat log API lokal
	$(DEV_COMPOSE) logs -f api

dev-admin: ## Buat admin lokal: make dev-admin EMAIL=a@b.c
	$(DEV_COMPOSE) exec api /app/api create-admin -email $(EMAIL)

backend-test: ## Unit test backend
	cd backend && go test -race ./...

test-integration: ## Semua test backend termasuk PostgreSQL sungguhan (butuh Docker)
	docker run -d --rm --name gkjw-pg-test -e POSTGRES_PASSWORD=test -e POSTGRES_DB=gkjw_test -p 55432:5432 postgres:17-alpine
	until docker exec gkjw-pg-test pg_isready -U postgres >/dev/null 2>&1; do sleep 1; done
	cd backend && TEST_DATABASE_URL="$(TEST_DB)" go test -race -count=1 -p 1 ./... ; status=$$?; docker stop gkjw-pg-test >/dev/null; exit $$status

# ── Aplikasi Flutter ──────────────────────────────────────────
app-run: ## Jalankan aplikasi ke backend lokal (emulator Android)
	cd frontend && flutter run --dart-define-from-file=config/dev.json

app-test: ## Test + analyze Flutter
	cd frontend && flutter analyze && flutter test

app-e2e: ## E2E di device: make app-e2e DEVICE=<id> [CONFIG=config/dev-ios.json]
	cd frontend && flutter test integration_test -d $(DEVICE) --dart-define-from-file=$(or $(CONFIG),config/dev.json)

app-build-apk: ## Build APK rilis ke backend produksi (config/prod.json)
	cd frontend && flutter build apk --release --obfuscate --split-debug-info=build/debug-info --dart-define-from-file=config/prod.json

# ── Website admin (React) ─────────────────────────────────────
admin-dev: ## Website admin di http://localhost:5174/admin/ (butuh `make dev`)
	cd admin-web && npm install --silent && npm run dev

admin-test: ## Typecheck, lint & test website admin
	cd admin-web && npm run typecheck && npm run lint && npm test

admin-build: ## Build website admin (hasil di admin-web/dist)
	cd admin-web && npm ci && npm run build
