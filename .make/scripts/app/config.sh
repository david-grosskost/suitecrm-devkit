#!/usr/bin/env bash
# Shows the final Compose configuration as Docker runs it.
# Warning: secrets from .env.local are shown in clear.
#
# @usage make app@config
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@config
compose config
