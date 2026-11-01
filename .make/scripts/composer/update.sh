#!/usr/bin/env bash
# Updates the PHP dependencies within the constraints of composer.json and
# rewrites composer.lock. Without PACKAGES, every dependency is updated.
#
# @usage make composer@update [PACKAGES="david-grosskost/suitecrm-devkit"]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

# PACKAGES holds package names separated by spaces: split on purpose.
# shellcheck disable=SC2086
composer_run update --no-interaction --no-progress ${PACKAGES:-}
