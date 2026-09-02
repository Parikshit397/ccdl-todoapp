#!/usr/bin/env bash
# Caddy smoke tests — turns README step 9's manual curl checks into a single
# runnable script with clear pass/fail output.
#
# Prereqs: Caddy running (from the project root: `caddy run`), frontend built
# (`npm run build` in frontend/), Tomcat STOPPED (these checks specifically
# verify Caddy's behavior when the backend is unreachable — see README step 9
# for why 502, not 404, is the expected/correct result).
#
# Usage: ./caddy/smoke-test.sh [base_url]
#   base_url defaults to http://localhost:3000

set -u

BASE_URL="${1:-http://localhost:3000}"
PASS=0
FAIL=0

pass() { echo "  PASS - $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL - $1"; FAIL=$((FAIL + 1)); }

echo "=== Caddy smoke tests against $BASE_URL ==="
echo "(expects the backend/Tomcat to be stopped for the 502 check)"
echo

# 1. Config validation
echo "[1] Config validation (Caddyfile syntax)"
if command -v caddy >/dev/null 2>&1; then
  if caddy validate --config ./caddy/Caddyfile >/tmp/caddy-validate.log 2>&1; then
    pass "caddy validate reports the Caddyfile is valid"
  else
    fail "caddy validate failed — see /tmp/caddy-validate.log"
  fi
else
  echo "  SKIP - 'caddy' binary not on PATH, skipping config validation"
fi
echo

# 2. Static file serving (frontend independent of backend)
echo "[2] Static file serving: GET / should be 200 even with the backend down"
STATUS=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/")
if [ "$STATUS" = "200" ]; then
  pass "GET / returned 200"
else
  fail "GET / returned $STATUS (expected 200) — is Caddy running from the project root?"
fi
echo

# 3. Reverse proxy is actually proxying (502, not 404, with backend down)
echo "[3] Reverse proxy routing: GET /api/todos should be 502 (backend down), not 404"
STATUS=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/api/todos")
if [ "$STATUS" = "502" ]; then
  pass "GET /api/todos returned 502 (proxy matched, upstream unreachable)"
elif [ "$STATUS" = "404" ]; then
  fail "GET /api/todos returned 404 — the 'handle /api/*' block isn't matching (check the Caddyfile)"
else
  fail "GET /api/todos returned $STATUS (expected 502 — is the backend actually stopped?)"
fi
echo

# 4. Security headers
echo "[4] Security headers are present on GET /"
HEADERS=$(curl -s -I "$BASE_URL/")
for h in "X-Frame-Options" "X-Content-Type-Options" "X-XSS-Protection"; do
  if echo "$HEADERS" | grep -qi "^$h:"; then
    pass "$h header present"
  else
    fail "$h header missing"
  fi
done
echo

# 5. SPA fallback (unknown path still serves index.html, not a 404)
echo "[5] SPA fallback: GET /some/random/path should be 200 (index.html), not 404"
STATUS=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/some/random/path")
if [ "$STATUS" = "200" ]; then
  pass "GET /some/random/path returned 200 (SPA fallback working)"
else
  fail "GET /some/random/path returned $STATUS (expected 200)"
fi
echo

echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
