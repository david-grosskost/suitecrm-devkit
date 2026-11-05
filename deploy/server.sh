#!/usr/bin/env bash
# Deploys a SuiteCRM instance on a server, from its directory
# (/srv/suitecrm/<APP_SLUG>), where deploy.yml copies it with the project's
# compose files, .env and .env.local.example. Needs only Docker: neither Git
# nor the devkit is installed on the server.
#
# deploy:   first time, creates .env.local; at each deployment, generates the
#           passwords it lacks (kept on the server only); then runs the image of APP_VERSION, waits until
#           every service is healthy, and installs SuiteCRM if not yet done.
# rollback: runs the previous version again (APP_PREVIOUS_VERSION). The code
#           only: a database already changed by the new version stays as is.
#           Given a version, only if it is the one running: a deployment that
#           failed before switching versions must not go one version back.
#
# seed:     loads the demo data into a running demo (database/seeders of the
#           image): the given seeders and those they depend on, all of them
#           by default, plus SEED_COUNT generated accounts. Safe to run again:
#           records are updated, never duplicated. Refused outside a demo.
#
# @usage APP_ENV=demo APP_SLUG=demo-core APP_HOST=demo-core.example.com \
#          APP_VERSION=0.2.0 bash server.sh deploy
# @usage bash server.sh rollback [0.2.0]
# @usage SEED_COUNT=200 bash server.sh seed [core/accounts core/volume …]
set -euo pipefail
cd "$(dirname "$0")"

LOCAL_ENV_FILE=".env.local"
# Seed runner of the image (suitecrm-core, and the projects built from it).
SEED_SCRIPT="/usr/local/share/suitecrm/database/seeders/seed.php"
# Generated accounts at most (seeder core/volume).
SEED_MAX_COUNT=1500

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

# Generates the secrets of .env.local: every key whose value is change-me in
# .env.local.example, when absent, empty or still change-me in .env.local.
# Runs at each deployment: a secret added to a new version of the project is
# generated on its first deployment, an existing one is never changed.
generate_secrets () {
  local key value
  while IFS='=' read -r key value || [ -n "$key" ]; do
    [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && [ "$value" = change-me ] || continue
    case "$(env_value "$LOCAL_ENV_FILE" "$key")" in
      ''|change-me)
        set_env_value "$LOCAL_ENV_FILE" "$key" "$(openssl rand -hex 24)"
        info "$key généré dans $LOCAL_ENV_FILE."
        ;;
    esac
  done < .env.local.example
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
    info "Premier déploiement : $LOCAL_ENV_FILE créé."
  fi
  generate_secrets

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
  if [ -n "${1:-}" ] && [ "$1" != "$current" ]; then
    info "Version en place : $current, pas $1 : rien à restaurer."
    return 0
  fi

  set_env_value "$LOCAL_ENV_FILE" APP_VERSION "$previous"
  set_env_value "$LOCAL_ENV_FILE" APP_PREVIOUS_VERSION "$current"
  info "Retour arrière : $current → $previous"
  start
}

seed () {
  local seeder count="${SEED_COUNT:-0}"
  [ -f "$LOCAL_ENV_FILE" ] || die "$LOCAL_ENV_FILE absent : instance jamais déployée"
  read_env_file .env
  read_env_file "$LOCAL_ENV_FILE"
  # Demo data has nothing to do in prod, nor anywhere but a demo.
  [ "${APP_ENV:-}" = demo ] || die "seed : réservé aux démos (APP_ENV=${APP_ENV:-vide})"

  [[ $count =~ ^[0-9]+$ ]] && [ "$count" -le "$SEED_MAX_COUNT" ] \
    || die "seed : SEED_COUNT doit être un nombre de 0 à $SEED_MAX_COUNT (reçu « $count »)"
  for seeder in "$@"; do
    [[ $seeder =~ ^[a-z0-9-]+/[a-z0-9-]+$ ]] \
      || die "seed : nom de seeder invalide « $seeder » (attendu : paquet/données, ex. core/accounts)"
  done
  [ "$(docker inspect -f '{{.State.Running}}' "$APP_SLUG-app" 2>/dev/null)" = true ] \
    || die "seed : conteneur $APP_SLUG-app arrêté ou absent"

  info "Seed de $APP_SLUG : ${*:-tous les seeders}, $count compte(s) généré(s)"
  docker exec -u www-data -e SEED_COUNT="$count" "$APP_SLUG-app" php "$SEED_SCRIPT" "$@"
}

case "${1:-}" in
  deploy) deploy ;;
  rollback) rollback "${2:-}" ;;
  seed) shift; seed "$@" ;;
  *) die "usage : server.sh deploy|rollback [version]|seed [seeder …]" ;;
esac
