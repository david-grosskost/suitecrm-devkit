#!/usr/bin/env bash
# Installs SuiteCRM from scratch. Safe to re-run: done steps are skipped.
# Settings and generated passwords are saved to .env.local, so later commands reuse them.
#
# @usage make app@install [APP_ENV=local|demo|prod] [APP_HOST=crm.example.com]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@install
"$SCRIPTS/app/check.sh"

if [ ! -f "$LOCAL_ENV_FILE" ]; then
  if [ "$APP_ENV" != local ] && [ -z "${APP_HOST:-}" ]; then
    die "app@install : APP_HOST obligatoire hors local (make app@install APP_ENV=$APP_ENV APP_HOST=…)"
  fi

  run cp .env.local.example "$LOCAL_ENV_FILE"

  # Every setting of .env.local.example given as a parameter is written to .env.local:
  #   make app@install APP_ENV=prod APP_HOST=crm.example.com
  while IFS='=' read -r key _; do
    [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && [ -n "${!key:-}" ] || continue
    set_env_value "$LOCAL_ENV_FILE" "$key" "${!key}"
  done < .env.local.example

  # Passwords not given as parameters are generated.
  for key in DB_PASSWORD DB_ROOT_PASSWORD ADMIN_PASSWORD; do
    if grep -q "^$key=change-me" "$LOCAL_ENV_FILE"; then
      set_env_value "$LOCAL_ENV_FILE" "$key" "$(secret)"
    fi
  done

  info "$LOCAL_ENV_FILE créé avec APP_ENV=$APP_ENV : les prochaines commandes l'utiliseront."
  read_env_file "$LOCAL_ENV_FILE"
fi

if [ "$APP_ENV" = local ]; then
  "$SCRIPTS/git/hooks.sh"
else
  # No commits on a server: only post-merge is useful, gitleaks is not needed.
  run git config core.hooksPath .githooks
fi

"$SCRIPTS/app/start.sh"

# SuiteCRM itself, installed once in the app volume. Values are passed by name
# (-e KEY): docker reads them from this script's environment, nothing is printed.
run docker exec -u www-data \
  -e DB_NAME -e DB_USER -e DB_PASSWORD -e APP_HOST -e ADMIN_USER -e ADMIN_PASSWORD \
  "$APP_SLUG-app" suitecrm-install

info "Administrateur : $ADMIN_USER (mot de passe dans $LOCAL_ENV_FILE)"
