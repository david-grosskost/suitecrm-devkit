#!/usr/bin/env bash
# Checks a SuiteCRM extension against the format of the projects: manifest
# (extension.json), composer.json, and where its files are (validate.php).
# A project without extension.json (not an extension) is skipped, not failed.
#
# @usage make extension@validate
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

if [ ! -f extension.json ]; then
  info "extension@validate : pas de extension.json, ce projet n'est pas une extension."
  exit 0
fi

# vendor/autoload.php: Composer's version parser, to check the SuiteCRM
# constraint (installed with the devkit's tools).
php_run -d auto_prepend_file=vendor/autoload.php "$(devkit_dir)/.make/scripts/extension/validate.php"
