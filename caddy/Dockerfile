# Multi-stage build: Node builds the same frontend/dist Lab 5 built by hand,
# then Caddy serves it + reverse-proxies to the backend — same single
# process doing both jobs, same Caddyfile, just containerized.
#
# Build context must be the PROJECT ROOT (not caddy/), since this needs both
# frontend/ and caddy/Caddyfile. See docker-compose.yml.

# ===== Stage 1: build the frontend =====
FROM node:20-alpine AS build
WORKDIR /build
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# ===== Stage 2: serve it with Caddy =====
FROM caddy:2.8-alpine
WORKDIR /srv

# Mirrors the exact relative layout Caddy expects when run from the project
# root on bare metal (`root * frontend/dist` in the Caddyfile) — so the
# Caddyfile itself needs zero path changes between bare-metal and Docker.
COPY --from=build /build/dist ./frontend/dist
COPY caddy/Caddyfile ./caddy/Caddyfile

EXPOSE 3000
CMD ["caddy", "run", "--config", "caddy/Caddyfile"]
