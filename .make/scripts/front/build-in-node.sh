#!/usr/bin/env bash
# Builds an extension's Angular module, inside the Node.js container of
# make front@build (build.sh): SuiteCRM's sources in /suitecrm (a Docker
# volume, cloned once), their dependencies and SuiteCRM's own Angular library
# (built once), then the module from /project/app, copied to /project/public.
# The sources are always at the same path: the build is then the same on
# every machine (the minified code depends on it).
#
# @usage NAME=<Name> VERSION=<suitecrm-version> HOST_UID=<uid> HOST_GID=<gid> build-in-node.sh
set -euo pipefail

src=/suitecrm/source

if [ ! -f "$src/package.json" ]; then
  echo "  Sources de SuiteCRM $VERSION (une fois)..."
  rm -rf "$src"
  git -c advice.detachedHead=false clone --quiet --depth 1 --branch "v$VERSION" \
    https://github.com/SuiteCRM/SuiteCRM-Core.git "$src"
fi
cd "$src"

echo "  Dépendances (yarn install)..."
corepack yarn install --immutable > yarn-install.log 2>&1 || { cat yarn-install.log; exit 1; }
# angular.json: SuiteCRM's, merged with those of extensions/*/app/.
corepack yarn merge-angular-json > /dev/null
if [ ! -f dist/core/package.json ]; then
  echo "  Bibliothèque core de SuiteCRM (une fois)..."
  corepack yarn build:core > build-core.log 2>&1 || { cat build-core.log; exit 1; }
fi

rm -rf "extensions/$NAME"
mkdir -p "extensions/$NAME"
cp -r /project/app "extensions/$NAME/app"
corepack yarn merge-angular-json > /dev/null

echo "  Module $NAME..."
corepack yarn build:extension "$NAME" > build.log 2>&1 || { cat build.log; exit 1; }
rm -rf /project/public
cp -r "extensions/$NAME/public" /project/public
# Built as root (the volume's owner): the module goes back to the user.
chown -R "$HOST_UID:$HOST_GID" /project/public
