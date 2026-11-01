#!/usr/bin/env bash
# Smoke test: SuiteCRM answers on its URL, shows the login page and lets the
# administrator log in. Playwright runs in Docker, browsers included; the tests
# are the devkit's tests/smoke/, shared by every SuiteCRM project.
#
# When the reverse proxy runs on this machine, the browser goes straight to
# Traefik on the shared network. Chromium resolves every *.localhost name to
# itself and ignores /etc/hosts (so --add-host has no effect): the address is
# forced with its --host-resolver-rules option instead (HOST_RESOLVER_RULES,
# read by playwright.config.ts). In local, the mkcert certificate is not
# trusted inside the container, so HTTPS errors are ignored there only.
#
# @usage make test@smoke [APP_ENV=local|demo|prod]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env test@smoke
[ -n "${APP_HOST:-}" ] \
  || die "test@smoke : APP_HOST inconnu — lancer « make app@install »"

# Credentials passed by name (-e KEY): their values are never printed.
args=(-e "BASE_URL=https://$APP_HOST" -e ADMIN_USER -e ADMIN_PASSWORD)

ip="$(traefik_ip)"
if [ -n "$ip" ]; then
  args+=(--network "$NETWORK" -e "HOST_RESOLVER_RULES=MAP $APP_HOST $ip")
fi
if [ "$APP_ENV" = local ]; then
  args+=(-e IGNORE_HTTPS_ERRORS=1)
fi

run docker run --rm --ipc=host "${args[@]}" \
  -v "$(host_pwd)/$(devkit_dir)/tests/smoke:/tests:ro" \
  -v playwright-npm-cache:/root/.npm \
  "$PLAYWRIGHT_IMAGE" bash -c "
    cp -r /tests /tmp/smoke && cd /tmp/smoke \
    && npm install --silent --no-save --no-audit --no-fund @playwright/test@$PLAYWRIGHT_VERSION \
    && npx playwright test"
