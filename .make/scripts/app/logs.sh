#!/usr/bin/env bash
# Follows the logs of one service (app by default).
#
# @usage make app@logs [SERVICE=app|db]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@logs
compose logs -f --tail=100 "${SERVICE:-app}"
