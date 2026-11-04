#!/usr/bin/env bash
# Fails if a PHP dependency of composer.lock has a known vulnerability
# (composer audit, against the Packagist security advisories).
# Abandoned packages are reported, never failed: there is nothing to fix at once.
# A project without composer.lock is skipped, not failed. The CI runs it too.
#
# @usage make security@deps
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

if [ ! -f composer.lock ]; then
  info "security@deps : pas de composer.lock, rien à vérifier."
  exit 0
fi

composer_run audit --locked --abandoned=report --no-interaction
