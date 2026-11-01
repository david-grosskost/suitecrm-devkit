#!/usr/bin/env bash
# Records every current PHPStan error in phpstan-baseline.neon, so that only
# new errors fail quality@stan. Run it once when adopting PHPStan, or after
# fixing errors to shrink the baseline; never to hide a new error.
#
# @usage make quality@baseline
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

[ -f phpstan.dist.neon ] \
  || die "quality@baseline : phpstan.dist.neon absent, rien à analyser"

php_run vendor/bin/phpstan analyse --no-progress --memory-limit=1G \
  --generate-baseline phpstan-baseline.neon
