# syntax=docker/dockerfile:1
# Image Caddy produksi yang sekaligus berisi website admin (hasil build di /srv/admin).

FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run build

FROM caddy:2-alpine
COPY --from=build /app/dist /srv/admin
