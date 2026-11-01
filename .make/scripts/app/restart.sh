#!/usr/bin/env bash
# Restarts SuiteCRM, e.g. after a change in .env.local.
#
# @usage make app@restart
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

"$SCRIPTS/app/stop.sh"
"$SCRIPTS/app/start.sh"
