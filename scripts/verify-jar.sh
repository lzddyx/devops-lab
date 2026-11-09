#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
jar="${1:-target/mytest.jar}"
port="${VERIFY_PORT:-18081}"
[[ -f "$jar" ]] || { echo "Missing JAR: $jar" >&2; exit 1; }
[[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1024 && port <= 65535 )) || {
  echo 'VERIFY_PORT must be an integer from 1024 to 65535.' >&2; exit 1;
}
log=$(mktemp "${TMPDIR:-/tmp}/mytest-verify.XXXXXX")
pid=''
cleanup() {
  if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
  rm -f "$log"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
java -jar "$jar" --server.address=127.0.0.1 --server.port="$port" >"$log" 2>&1 &
pid=$!
ready=false
for _ in $(seq 1 60); do
  if ! kill -0 "$pid" 2>/dev/null; then cat "$log" >&2; exit 1; fi
  if grep -Fq 'Started MytestApplication' "$log" && [[ "$(curl --silent --max-time 1 --write-out '|%{http_code}' "http://127.0.0.1:$port/health" || true)" == 'OK|200' ]]; then ready=true; break; fi
  sleep 1
done
[[ "$ready" == true ]] || { cat "$log" >&2; echo 'Application startup timed out.' >&2; exit 1; }
sleep 1
kill -0 "$pid" 2>/dev/null || { cat "$log" >&2; exit 1; }
response=$(curl --fail --silent --show-error --max-time 5 --write-out '|%{http_code}' "http://127.0.0.1:$port/test")
[[ "$response" == 'Hello Jenkins!|200' ]] || { echo 'Unexpected /test response.' >&2; exit 1; }
status=$(curl --silent --max-time 5 --output /dev/null --write-out '%{http_code}' "http://127.0.0.1:$port/missing")
[[ "$status" == 404 ]] || { echo "Expected 404, got $status" >&2; exit 1; }
printf 'Executable JAR verified: /test=200, /health=200, unknown path=404 (loopback port %s).\n' "$port"
