#!/usr/bin/env bash
# Builds the Module Loader package of a SuiteCRM extension, in build/
# (<slug>-<version>.zip, never committed): see build.php for its content.
# A project without extension.json (not an extension) is skipped, not failed.
#
# @usage make package@build
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

if [ ! -f extension.json ]; then
  info "package@build : pas de extension.json, ce projet n'est pas une extension."
  exit 0
fi

# The SuiteCRM the Angular module is built against (make front@build): the
# package is accepted by the same minor version only.
php_run "$(devkit_dir)/.make/scripts/package/build.php" "$SUITECRM_VERSION"
