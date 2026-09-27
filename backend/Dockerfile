# syntax=docker/dockerfile:1

# ---- build ----
FROM golang:1.26-alpine AS build
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/api ./cmd/api \
    && mkdir -p /out/data/uploads

# ---- runtime ----
# distroless: tanpa shell/package manager, berjalan sebagai user non-root.
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/api /app/api
COPY --from=build --chown=nonroot:nonroot /out/data /data

ENV PORT=8080 \
    UPLOAD_DIR=/data/uploads
EXPOSE 8080
VOLUME ["/data/uploads"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD ["/app/api", "healthcheck"]

ENTRYPOINT ["/app/api"]
