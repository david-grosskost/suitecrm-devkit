#!/usr/bin/env bash
# Regression test of a local instance, with every extension it has installed:
# a Quick Repair first (as after any change of extension), then Playwright
# goes through the main screens as the administrator and fails on a
# JavaScript error, a server error (HTTP 5xx), a PHP error shown in the page
# or a raw label key (LBL_…, LNK_…). The tests are the devkit's
# tests/regression/, shared by every SuiteCRM project.
#
# Local only (and the CI, which runs a local instance): the test opens
# creation forms and needs the administrator's password.
#
# @usage make test@regression
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env test@regression
require_app_env test@regression local
[ -n "${APP_HOST:-}" ] \
  || die "test@regression : APP_HOST inconnu — lancer « make app@install »"
[ -n "${ADMIN_PASSWORD:-}" ] && [ "$ADMIN_PASSWORD" != change-me ] \
  || die "test@regression : ADMIN_PASSWORD absent de .env.local"

"$SCRIPTS/app/repair.sh"
playwright_run regression
