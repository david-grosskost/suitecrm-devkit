#!/usr/bin/env bash
# Smoke test: SuiteCRM answers on its URL, shows the login page and lets the
# administrator log in. Playwright runs in Docker, browsers included; the tests
# are the devkit's tests/smoke/, shared by every SuiteCRM project.
#
# @usage make test@smoke [APP_ENV=local|demo|prod]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env test@smoke
[ -n "${APP_HOST:-}" ] \
  || die "test@smoke : APP_HOST inconnu — lancer « make app@install »"

playwright_run smoke
