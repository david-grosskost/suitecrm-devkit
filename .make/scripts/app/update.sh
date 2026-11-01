#!/usr/bin/env bash
# Pulls updated images, rebuilds the app image and recreates the containers.
#
# @usage make app@update
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

load_env app@update
compose pull --ignore-buildable
compose build --pull
compose up -d
