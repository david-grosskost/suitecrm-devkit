#!/usr/bin/env bash
# Unit tests (PHPUnit), with the project's phpunit.xml.dist. A project without
# phpunit.xml.dist (no unit tests) is skipped, not failed.
#
# @usage make test@unit
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

if [ ! -f phpunit.xml.dist ]; then
  info "test@unit : pas de phpunit.xml.dist, aucun test unitaire."
  exit 0
fi

php_run vendor/bin/phpunit --colors=always
