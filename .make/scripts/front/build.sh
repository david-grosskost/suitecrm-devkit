#!/usr/bin/env bash
# Builds the Angular module of an extension: its sources (app/) against those
# of SuiteCRM (SuiteCRM-Core, the version of the image, $SUITECRM_VERSION),
# into public/, which is committed: suitecrm-core installs it as is (no
# Node.js in the image), and the CI checks that it matches app/
# (make front@check). A project without app/ is skipped, not failed.
#
# The Angular project is named after the extension's directory in SuiteCRM:
# the slug in PascalCase (front-customizer → FrontCustomizer), as in
# config/extension.php. SuiteCRM's sources, their dependencies and SuiteCRM's
# own Angular library are kept in the Docker volume suitecrm-front-<version>:
# the first build takes a few minutes, the next ones less than one
# (docker volume rm suitecrm-front-<version> to start again).
#
# @usage make front@build
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

if [ ! -d app ]; then
  info "front@build : pas de dossier app/, cette extension n'a pas de module Angular."
  exit 0
fi
[ -f extension.json ] || die "front@build : extension.json absent"

slug="$(sed -nE 's/^[[:space:]]*"slug"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' extension.json | head -n1)"
[ -n "$slug" ] || die "front@build : slug introuvable dans extension.json"
name="$(sed -E 's/(^|-)([a-z0-9])/\U\2/g' <<< "$slug")"

# SuiteCRM's sources and their dependencies (2.5 GB) in a Docker volume, kept
# between builds: much faster than in the project folder under Docker Desktop.
run docker run --rm \
  -e COREPACK_HOME=/suitecrm/corepack -e COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
  -e COREPACK_NPM_REGISTRY=https://registry.npmjs.org -e YARN_ENABLE_GLOBAL_CACHE=false \
  -e NAME="$name" -e VERSION="$SUITECRM_VERSION" -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -v "suitecrm-front-$SUITECRM_VERSION:/suitecrm" \
  -v "$(host_pwd):/project" -w /project "$NODE_IMAGE" \
  bash "$(devkit_dir)/.make/scripts/front/build-in-node.sh"
info "Module Angular $name construit dans public/ (SuiteCRM $SUITECRM_VERSION)."
