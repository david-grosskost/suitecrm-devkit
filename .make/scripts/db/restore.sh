#!/usr/bin/env bash
# Restores a dump of .tools/dumps/ into the database of the local instance
# (the latest one by default). The current database is dumped first
# (NAME=before-restore), so a restore can always be undone. The SuiteCRM 8
# cache is emptied afterwards: it holds data of the replaced database.
#
# Local only: restoring a demo or a production goes through the server
# procedures, not this command.
#
# @usage make db@restore [FILE=.tools/dumps/<dump>.sql.gz]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env db@restore
require_app_env db@restore local

db="${APP_SLUG:?APP_SLUG manquant dans .env}-db"
app="$APP_SLUG-app"
docker inspect "$db" >/dev/null 2>&1 \
  || die "db@restore : conteneur $db absent — lancer « make app@start »"

file="${FILE:-}"
if [ -z "$file" ]; then
  # Names start with the slug and a sortable date: the last one is the latest.
  file="$(find .tools/dumps -maxdepth 1 -name "$APP_SLUG-*.sql.gz" 2>/dev/null | sort | tail -n 1)"
  [ -n "$file" ] || die "db@restore : aucun dump dans .tools/dumps — lancer « make db@dump »"
fi
[ -f "$file" ] || die "db@restore : fichier introuvable : $file"
gzip -t "$file" || die "db@restore : $file n'est pas un dump complet (gzip invalide)"

info "La base actuelle sera remplacée par : $file"
read -r -p "  Continuer ? [o/N] " answer
[[ $answer =~ ^[oOyY]$ ]] || die "db@restore : annulé."

NAME=before-restore "$SCRIPTS/db/dump.sh"

info "Restauration de $file..."
# The dump has no CREATE DATABASE: it goes into the instance's database.
# shellcheck disable=SC2016
gzip -dc "$file" | docker exec -i "$db" sh -c '
  MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot "$MARIADB_DATABASE"'

if docker inspect "$app" >/dev/null 2>&1; then
  run docker exec -u www-data "$app" rm -rf /var/www/html/cache/prod
fi
info "Base restaurée. Recharger la page (Ctrl+F5) ; se reconnecter si la session a expiré."
