#!/usr/bin/env bash
set -euo pipefail
cd "${WORKSPACE:?Jenkins WORKSPACE is required}"
mvn -B -ntp clean verify
bash scripts/verify-jar.sh
# No SSH credentials, Docker commands, or deployment permissions.
