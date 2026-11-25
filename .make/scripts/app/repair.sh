#!/usr/bin/env bash
# Quick Repair and Rebuild of the running instance, as Administration →
# Réparer → Réparation rapide et reconstruction does it: rebuilds the
# extensions (custom/Extension/… merged into custom/modules/…/Ext/), clears the
# legacy caches and applies the database changes the extensions ask for. Then
# empties the cache of SuiteCRM 8 (labels and metadata served to the Angular
# interface), rebuilt on the next request.
#
# Uses the repair script of the suitecrm-core image, so it works in every
# project built on that image (suitecrm-core, client projects).
#
# @usage make app@repair [APP_ENV=local|demo|prod]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@repair

container="${APP_SLUG:?APP_SLUG manquant dans .env}-app"
docker inspect "$container" >/dev/null 2>&1 \
  || die "app@repair : conteneur $container absent — lancer « make app@start »"

run docker exec -u www-data "$container" php /usr/local/share/suitecrm/repair.php
run docker exec -u www-data "$container" rm -rf /var/www/html/cache/prod
info "Cache de SuiteCRM 8 vidé : recharger la page (Ctrl+F5) pour voir les changements."
