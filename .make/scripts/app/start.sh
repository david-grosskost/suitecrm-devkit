#!/usr/bin/env bash
# Starts SuiteCRM, after checking what it needs. Waits until every service is healthy.
#
# @usage make app@start [APP_ENV=local|demo|prod]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@start

[ -f "$LOCAL_ENV_FILE" ] \
  || die "app@start : $LOCAL_ENV_FILE absent — lancer « make app@install »"

network_exists \
  || die "app@start : réseau « $NETWORK » absent — démarrer le reverse-proxy (« make app@start » dans son dossier)"

compose up -d --build --wait

printf '\n  SuiteCRM : \033[36mhttps://%s\033[0m\n\n' "$APP_HOST"
