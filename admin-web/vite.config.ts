/// <reference types="vitest/config" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Website admin disajikan di https://{DOMAIN}/admin/ (satu domain dengan API → tanpa CORS).
export default defineConfig({
  base: '/admin/',
  plugins: [react()],
  // Jangan sisipkan aset sebagai data: URI — CSP produksi hanya mengizinkan font dari 'self'.
  build: { assetsInlineLimit: 0 },
  server: {
    port: 5174,
    // Saat development, teruskan API & file ke backend lokal (`make dev`).
    proxy: {
      '/api': 'http://localhost:8080',
      '/files': 'http://localhost:8080',
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    css: false,
  },
})
