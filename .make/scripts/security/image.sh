#!/usr/bin/env bash
# Scans a Docker image for known vulnerabilities (Trivy), then fails if the
# packages of its system (Debian) have a critical one with a fix available:
# rebuilding the image with the updated base image fixes it.
#
# The libraries bundled with the application (e.g. SuiteCRM's vendor/) are
# listed too, from high severity, but never fail: they come with SuiteCRM and
# are fixed by upgrading it, not by us.
#
# Without IMAGE, scans the image of the app service of compose.yaml (the one
# built by make app@update). The release workflow scans the image it built.
#
# @usage make security@image [IMAGE=ghcr.io/owner/project:1.2.0]
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

# Image of the app service, read in the resolved compose configuration
# (config --images lists every service, in no useful order).
compose_app_image () {
  docker compose --env-file "$ENV_FILE" -f compose.yaml config 2>/dev/null | awk '
    /^  app:$/ { app = 1; next }
    app && /^  [^ ]/ { exit }
    app && /^    image: / { print $2; exit }'
}

image="${IMAGE:-}"
if [ -z "$image" ]; then
  image="$(compose_app_image)"
  [ -n "$image" ] || die "security@image : IMAGE manquant, et pas d'image pour le service app de compose.yaml"
fi
docker image inspect "$image" >/dev/null 2>&1 \
  || die "security@image : image $image absente de cette machine (make app@update la construit)"

# Trivy reads the image from the local Docker; its vulnerability database is
# kept in a volume between runs.
trivy () {
  run docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v trivy-cache:/root/.cache/trivy \
    "$TRIVY_IMAGE" image --no-progress --skip-version-check --ignore-unfixed "$@" "$image"
}

info "Bibliothèques de l'application (pour information) :"
trivy --pkg-types library --severity HIGH,CRITICAL --exit-code 0

info "Paquets du système (bloquant si critique) :"
if trivy --pkg-types os --severity CRITICAL --exit-code 1; then
  info "Image $image : aucune faille critique corrigeable dans le système."
else
  die "security@image : faille critique corrigeable dans $image → reconstruire l'image (make app@update) sur une image de base à jour"
fi
