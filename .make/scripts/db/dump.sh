#!/usr/bin/env bash
# Dumps the database of the instance into .tools/dumps/ (never committed):
# <slug>-<date>[-<NAME>].sql.gz. The credentials are read inside the database
# container, from the variables of the MariaDB image: nothing is printed.
#
# @usage make db@dump [NAME=before-import] [APP_ENV=local|demo|prod]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env db@dump

container="${APP_SLUG:?APP_SLUG manquant dans .env}-db"
docker inspect "$container" >/dev/null 2>&1 \
  || die "db@dump : conteneur $container absent — lancer « make app@start »"

label="${NAME:-}"
[[ -z $label || $label =~ ^[a-z0-9-]+$ ]] \
  || die "db@dump : NAME ne doit contenir que des minuscules, chiffres et tirets"

dir=.tools/dumps
mkdir -p "$dir"
file="$dir/$APP_SLUG-$(date +%Y%m%d-%H%M%S)${label:+-$label}.sql.gz"

info "Dump de la base de $APP_SLUG..."
# Single quotes: expanded inside the container, not here.
# shellcheck disable=SC2016
docker exec "$container" sh -c '
  MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb-dump -uroot \
    --single-transaction --routines --triggers --events "$MARIADB_DATABASE"' \
  | gzip > "$file.tmp"
# Renamed once complete: a failed dump never looks like a good one.
mv "$file.tmp" "$file"

info "Dump écrit : $file ($(du -h "$file" | cut -f1))"
