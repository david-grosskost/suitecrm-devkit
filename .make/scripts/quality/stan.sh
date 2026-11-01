#!/usr/bin/env bash
# Static analysis of the PHP code (PHPStan), with the project's phpstan.dist.neon.
# Errors already listed in phpstan-baseline.neon are tolerated; any new one fails.
#
# @usage make quality@stan
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

[ -f phpstan.dist.neon ] \
  || die "quality@stan : phpstan.dist.neon absent, rien à analyser"

php_run vendor/bin/phpstan analyse --no-progress --memory-limit=1G
