#!/usr/bin/env bash
# Fixes the PHP code style in place (PHP-CS-Fixer). Review the changes with
# git diff before committing.
#
# @usage make quality@fix
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

[ -f .php-cs-fixer.dist.php ] \
  || die "quality@fix : .php-cs-fixer.dist.php absent, rien à corriger"

php_run vendor/bin/php-cs-fixer fix --show-progress=none
