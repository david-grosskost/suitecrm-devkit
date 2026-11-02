#!/usr/bin/env bash
# Deploys a SuiteCRM instance on a server, from its directory
# (/srv/suitecrm/<APP_SLUG>), where deploy.yml copies it with the project's
# compose files, .env and .env.local.example. Needs only Docker: neither Git
# nor the devkit is installed on the server.
#
# deploy:   first time, creates .env.local (generated passwords, kept on the
#           server only); then runs the image of APP_VERSION, waits until
#           every service is healthy, and installs SuiteCRM if not yet done.
# rollback: runs the previous version again (APP_PREVIOUS_VERSION). The code
#           only: a database already changed by the new version stays as is.
#
# @usage APP_ENV=demo APP_SLUG=demo-core APP_HOST=demo-core.example.com \
#          APP_VERSION=0.2.0 bash server.sh deploy
# @usage bash server.sh rollback
set -euo pipefail
cd "$(dirname "$0")"

LOCAL_ENV_FILE=".env.local"

# Prints an error and exits.
#
# @param string $* Message
die () { printf 'server : %s\n' "$*" >&2; exit 1; }

# Prints an indented message.
#
# @param string $* Message
info () { printf '  %s\n' "$*"; }

# Value of a key in an env file, empty if absent.
#
# @param string $1 File
# @param string $2 Key
env_value () { sed -n "s/^$2=//p" "$1" | tail -n 1; }

# Sets KEY=value in an env file: replaces the line, or adds it.
#
# @param string $1 File
# @param string $2 Key
# @param string $3 Value
set_env_value () {
  if grep -q "^$2=" "$1"; then
    awk -v k="$2" -v v="$3" 'index($0, k "=") == 1 { $0 = k "=" v } { print }' \
      "$1" > "$1.tmp"
    cat "$1.tmp" > "$1"
    rm -f "$1.tmp"
  else
    printf '%s=%s\n' "$2" "$3" >> "$1"
  fi
}

# Reads a KEY=value file into the environment, without executing it.
#
# @param string $1 File
read_env_file () {
  local key value
  while IFS='=' read -r key value || [ -n "$key" ]; do
    [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    export "$key=$value"
  done < "$1"
}

# Runs docker compose with both env files, the base file and the APP_ENV overlay.
#
# @param string $@ docker compose arguments
compose () {
  docker compose --env-file .env --env-file "$LOCAL_ENV_FILE" \
    -f compose.yaml -f "compose.$APP_ENV.yaml" "$@"
}

# Starts the version written in .env.local and waits until it is healthy.
start () {
  info "Version $(env_value "$LOCAL_ENV_FILE" APP_VERSION)"
  compose pull --quiet app
  compose up -d --wait --wait-timeout 300 --remove-orphans
}

deploy () {
  local key current
  for key in APP_ENV APP_SLUG APP_HOST APP_VERSION; do
    [ -n "${!key:-}" ] || die "$key manquant"
  done
  [[ $APP_SLUG =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "APP_SLUG invalide : $APP_SLUG"

  if [ ! -f "$LOCAL_ENV_FILE" ]; then
    # Created unreadable by others: it holds the passwords.
    ( umask 077 && cp .env.local.example "$LOCAL_ENV_FILE" )
    for key in DB_PASSWORD DB_ROOT_PASSWORD ADMIN_PASSWORD; do
      set_env_value "$LOCAL_ENV_FILE" "$key" "$(openssl rand -hex 24)"
    done
    info "Premier déploiement : $LOCAL_ENV_FILE créé (mots de passe générés)."
  fi

  # Settings given by the workflow: they may change from one deployment to the next.
  for key in APP_ENV APP_SLUG APP_HOST; do
    set_env_value "$LOCAL_ENV_FILE" "$key" "${!key}"
  done

  current="$(env_value "$LOCAL_ENV_FILE" APP_VERSION)"
  if [ -n "$current" ] && [ "$current" != "$APP_VERSION" ]; then
    set_env_value "$LOCAL_ENV_FILE" APP_PREVIOUS_VERSION "$current"
  fi
  set_env_value "$LOCAL_ENV_FILE" APP_VERSION "$APP_VERSION"

  start

  # SuiteCRM itself, installed once in the app volume (does nothing afterwards).
  # Values are passed by name (-e KEY): nothing is printed.
  read_env_file .env
  read_env_file "$LOCAL_ENV_FILE"
  docker exec -u www-data \
    -e DB_NAME -e DB_USER -e DB_PASSWORD -e APP_HOST -e ADMIN_USER -e ADMIN_PASSWORD \
    "$APP_SLUG-app" suitecrm-install

  info "Déployé : https://$APP_HOST ($APP_VERSION)"
}

rollback () {
  local current previous
  [ -f "$LOCAL_ENV_FILE" ] || die "$LOCAL_ENV_FILE absent : rien à restaurer"
  read_env_file "$LOCAL_ENV_FILE"
  current="$(env_value "$LOCAL_ENV_FILE" APP_VERSION)"
  previous="$(env_value "$LOCAL_ENV_FILE" APP_PREVIOUS_VERSION)"
  [ -n "$previous" ] || die "aucune version précédente : rien à restaurer"

  set_env_value "$LOCAL_ENV_FILE" APP_VERSION "$previous"
  set_env_value "$LOCAL_ENV_FILE" APP_PREVIOUS_VERSION "$current"
  info "Retour arrière : $current → $previous"
  start
}

case "${1:-}" in
  deploy) deploy ;;
  rollback) rollback ;;
  *) die "usage : server.sh deploy|rollback" ;;
esac
