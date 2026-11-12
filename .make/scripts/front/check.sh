#!/usr/bin/env bash
# Checks that the committed Angular module of an extension (public/) is the
# one its sources (app/) build: rebuilds it (make front@build), then compares.
# Run by the CI. A project without app/ is skipped, not failed.
#
# @usage make front@check
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

if [ ! -d app ]; then
  info "front@check : pas de dossier app/, cette extension n'a pas de module Angular."
  exit 0
fi

"$SCRIPTS/front/build.sh"

if [ -n "$(git status --porcelain -- public)" ]; then
  git status --short -- public | head -n 20 >&2
  die "front@check : public/ ne correspond pas à app/ → make front@build, puis commiter public/"
fi
info "Module Angular : public/ correspond à app/."
