#!/usr/bin/env bash
# Static analysis of the PHP code (PHPStan), with the project's phpstan.dist.neon.
# Errors already listed in phpstan-baseline.neon are tolerated; any new one fails.
# A project without phpstan.dist.neon (no PHP of its own) is skipped, not failed.
#
# @usage make quality@stan
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

if [ ! -f phpstan.dist.neon ]; then
  info "quality@stan : pas de phpstan.dist.neon, rien à analyser."
  exit 0
fi

php_run vendor/bin/phpstan analyse --no-progress --memory-limit=1G
