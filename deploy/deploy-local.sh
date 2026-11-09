#!/usr/bin/env bash
# Run manually in the Ubuntu ARM64 terminal. Never add this script to Jenkins.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
project=devops-episode10
app_image=mytest:episode10
expected_jar_sha=e5852c31074620ee307e75dc8fe27b22345093a0c38aef9d9adc8e1528104120
base_image=public.ecr.aws/docker/library/eclipse-temurin@sha256:5bdb2989179defb8abd386a97b34407ebeccf9fdae11838576983254b5e8e5e2
expected_config_digest=sha256:cd9edca13a4c03d1cacfde0cab66cdfbbcb44dcf1c7a1f3a5f800cc6e5c2b6ec
fail() { printf 'STOP: %s\n' "$*" >&2; exit 1; }
[[ $# == 0 || ( $# == 1 && $1 == --check ) ]] || fail 'Usage: bash deploy-local.sh [--check]'
for tool in docker curl ss python3 sha256sum; do
  command -v "$tool" >/dev/null || fail "Missing tool: $tool"
done
[[ "$(uname -m)" == aarch64 ]] || fail 'This pinned deployment is for Linux ARM64 only.'
[[ -s mytest.jar ]] || fail 'Download and verify target/mytest.jar before deploying.'
[[ -f verify-base-image.py ]] || fail 'Missing verify-base-image.py; copy the deployment helpers together.'
printf '%s  mytest.jar\n' "$expected_jar_sha" | sha256sum --check --status || fail 'JAR differs from the verified Jenkins #1 artifact; no Docker action was taken.'
listeners=$(ss -ltnH 'sport = :8081')
[[ -z "$listeners" ]] || fail 'Port 8081 is occupied; existing services were not changed.'

# Validate the exact Compose configuration without reading a local .env file.
compose=(sudo env APP_PORT=8081 docker compose --env-file /dev/null
  -f "$PWD/compose.yaml" -p "$project")
APP_PORT=8081 docker compose --env-file /dev/null -f compose.yaml -p "$project" config --format json |
python3 -I -c '
import json, sys
c = json.load(sys.stdin)
s = c.get("services", {})
assert set(s) == {"mytest"}, "Only the mytest service is allowed"
s = s["mytest"]
p = s.get("ports", [])
assert len(p) == 1 and p[0].get("host_ip") == "127.0.0.1" and str(p[0].get("published")) == "8081" and p[0].get("target") == 8080, "Unexpected published port"
assert not s.get("privileged") and not s.get("volumes") and not s.get("devices"), "Unexpected host access"
assert not s.get("network_mode") and not s.get("pid") and not s.get("ipc"), "Unexpected host namespace"
assert s.get("read_only") is True and "ALL" in s.get("cap_drop", []) and not s.get("cap_add"), "Unexpected container capabilities"
assert "no-new-privileges:true" in s.get("security_opt", []), "Missing no-new-privileges"
assert s.get("image") == "mytest:episode10", "Unexpected application image"
'

if [[ "${1:-}" == --check ]]; then
  printf 'Preflight passed: verified JAR, unused port, safe Compose configuration. No sudo or Docker daemon actions.\n'
  exit 0
fi

# Keep a private local log so failures can be diagnosed without rerunning steps.
log_file="$PWD/deploy-run-$(date -u +%Y%m%dT%H%M%SZ)-$$.log"
(umask 077; : > "$log_file")
exec > >(tee -a "$log_file") 2>&1
printf 'Deployment log: %s\n' "$log_file"

# sudo is used only for Docker commands, not for this whole script.
sudo -v
containers=$(sudo docker ps -aq --filter "label=com.docker.compose.project=$project")
[[ -z "$containers" ]] || fail 'A same-name Compose project exists; nothing was replaced.'
networks=$(sudo docker network ls -q --filter "label=com.docker.compose.project=$project")
[[ -z "$networks" ]] || fail 'A same-name Compose network exists; inspect it before retrying.'
images=$(sudo docker image ls -q "$app_image")
[[ -z "$images" ]] || fail 'The application image tag already exists; nothing was overwritten.'

printf 'JAR SHA-256: '; sha256sum mytest.jar
printf 'Pulling the digest-verified Docker Official Image from ECR...\n'
sudo docker pull --platform linux/arm64 "$base_image"
sudo docker image inspect --format '{{json .}}' "$base_image" |
  python3 -I "$PWD/verify-base-image.py" "$base_image" "$expected_config_digest"
"${compose[@]}" build --build-arg "BASE_IMAGE=$base_image" mytest
"${compose[@]}" up -d --no-build --pull never --no-recreate mytest
"${compose[@]}" ps
# A listening Docker proxy can reset connections while the JVM is still starting.
# Poll the idempotent health GET for all transient startup failures, not just ECONNREFUSED.
printf 'Waiting up to about 60 seconds for the application to become ready...\n'
deadline=$((SECONDS + 60))
health=''
ready=false
while (( SECONDS < deadline )); do
  if health=$(curl --silent --connect-timeout 1 --max-time 2 --write-out '|%{http_code}' http://127.0.0.1:8081/health) && [[ "$health" == 'OK|200' ]]; then
    ready=true
    break
  fi
  sleep 1
done
[[ "$ready" == true ]] || fail 'Health check did not become ready within 60 seconds; preserve the container and inspect its logs.'
response=$(curl --fail --silent --show-error --max-time 5 --write-out '|%{http_code}' http://127.0.0.1:8081/test)
[[ "$response" == 'Hello Jenkins!|200' ]] || fail 'Application check failed; preserve the container and inspect its logs.'
printf 'SUCCESS: /test=200 Hello Jenkins!; /health=200 OK.\n'
printf 'No cleanup, service replacement, or Jenkins permission changes were performed.\n'
