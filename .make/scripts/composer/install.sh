#!/usr/bin/env bash
# Installs the PHP dependencies exactly as composer.lock lists them.
#
# @usage make composer@install
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

composer_run install --no-interaction --no-progress
