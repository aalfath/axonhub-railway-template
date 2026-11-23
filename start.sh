#!/bin/sh
# Railway wrapper for AxonHub.
# - listens on $PORT, uses PostgreSQL from AXONHUB_DB_DSN
# - creates the owner account on first boot from ADMIN_EMAIL / ADMIN_PASSWORD,
#   so nobody can claim the instance through the public setup wizard
# - exits non-zero whenever AxonHub stops, so Railway's ON_FAILURE restarts it
set -u

export AXONHUB_SERVER_PORT="${PORT:-8090}"
export AXONHUB_DB_DIALECT="${AXONHUB_DB_DIALECT:-postgres}"
export AXONHUB_DB_MAX_OPEN_CONNS="${AXONHUB_DB_MAX_OPEN_CONNS:-10}"
export AXONHUB_DB_MAX_IDLE_CONNS="${AXONHUB_DB_MAX_IDLE_CONNS:-5}"
export AXONHUB_LOG_ENCODING="${AXONHUB_LOG_ENCODING:-json}"
export AXONHUB_LOG_LEVEL="${AXONHUB_LOG_LEVEL:-info}"
# Keep the Go runtime within a small Railway plan.
export GOMAXPROCS="${GOMAXPROCS:-2}"
export GOMEMLIMIT="${GOMEMLIMIT:-400MiB}"

if [ -z "${AXONHUB_DB_DSN:-}" ]; then
  echo "axonhub-start: AXONHUB_DB_DSN is not set" >&2
  exit 1
fi

PORT_LOCAL="$AXONHUB_SERVER_PORT"
BASE="http://127.0.0.1:${PORT_LOCAL}"

/app/axonhub &
PID=$!

term() { kill -TERM "$PID" 2>/dev/null; wait "$PID"; exit 143; }
trap term TERM INT

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

init_owner() {
  i=0
  while [ $i -lt 300 ]; do
    kill -0 "$PID" 2>/dev/null || return 0
    if wget -q -T 3 -O /dev/null "$BASE/health" 2>/dev/null; then break; fi
    i=$((i + 1)); sleep 1
  done
  status=$(wget -q -T 5 -O - "$BASE/admin/system/status" 2>/dev/null || true)
  case "$status" in
    *'"isInitialized":true'*) echo "axonhub-start: already initialised"; return 0 ;;
    *'"isInitialized":false'*) ;;
    *) echo "axonhub-start: could not read system status: $status" >&2; return 0 ;;
  esac
  if [ -z "${ADMIN_EMAIL:-}" ] || [ -z "${ADMIN_PASSWORD:-}" ]; then
    echo "axonhub-start: WARNING not initialised and ADMIN_EMAIL/ADMIN_PASSWORD unset; the setup page is open to anyone" >&2
    return 0
  fi
  body=$(printf '{"ownerEmail":"%s","ownerPassword":"%s","ownerFirstName":"%s","ownerLastName":"%s","brandName":"%s"}' \
    "$(json_escape "$ADMIN_EMAIL")" "$(json_escape "$ADMIN_PASSWORD")" \
    "$(json_escape "${ADMIN_FIRST_NAME:-Admin}")" "$(json_escape "${ADMIN_LAST_NAME:-User}")" \
    "$(json_escape "${BRAND_NAME:-AxonHub}")")
  out=$(wget -q -T 30 -O - --header 'Content-Type: application/json' --post-data "$body" "$BASE/admin/system/initialize" 2>&1 || true)
  case "$out" in
    *'"success":true'*) echo "axonhub-start: owner account created for ${ADMIN_EMAIL}" ;;
    *) echo "axonhub-start: initialise failed: $out" >&2 ;;
  esac
}

init_owner

wait "$PID"
code=$?
echo "axonhub-start: axonhub exited with code $code" >&2
[ "$code" -eq 0 ] && code=1
exit "$code"
