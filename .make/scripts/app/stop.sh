#!/usr/bin/env bash
# Stops SuiteCRM. Volumes (database, uploads) are kept.
#
# @usage make app@stop
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@stop
compose down
