#!/usr/bin/env bash
# Installs the pinned GitHub CLI (gh) into .tools/bin/, used by make git@pr.
# The download is verified against the checksums published by GitHub. Does
# nothing if this version is already installed. Signing in stays with the
# person, once per machine: .tools/bin/gh auth login (gh keeps the token in
# the system's credential store, never in the project).
#
# @usage make git@gh
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

GH_VERSION=2.103.3
BIN_DIR=.tools/bin
RELEASES=https://github.com/cli/cli/releases/download

case "$(uname -s)" in
  Linux)                os=linux   ext=tar.gz exe=gh ;;
  Darwin)               os=macOS   ext=zip    exe=gh ;;
  MINGW*|MSYS*|CYGWIN*) os=windows ext=zip    exe=gh.exe ;;
  *) die "git@gh : système non pris en charge ($(uname -s))" ;;
esac

case "$(uname -m)" in
  x86_64|amd64)  arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) die "git@gh : processeur non pris en charge ($(uname -m))" ;;
esac

if [ -x "$BIN_DIR/$exe" ] \
  && "$BIN_DIR/$exe" --version 2>/dev/null | grep -q "gh version $GH_VERSION "; then
  info "gh $GH_VERSION déjà installé ($BIN_DIR/$exe)."
  exit 0
fi

name="gh_${GH_VERSION}_${os}_${arch}"
asset="$name.$ext"
# Inside the project, as a relative path: under Git Bash, a native curl.exe
# cannot write to /tmp/... (MSYS_NO_PATHCONV, set by lib.sh, keeps the path
# as is). .tools/ is ignored by Git.
mkdir -p .tools
tmp="$(mktemp -d .tools/download.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

run curl -sSfL -o "$tmp/$asset" "$RELEASES/v$GH_VERSION/$asset"
curl -sSfL -o "$tmp/checksums.txt" "$RELEASES/v$GH_VERSION/gh_${GH_VERSION}_checksums.txt"

expected="$(awk -v f="$asset" '$2 == f { print $1 }' "$tmp/checksums.txt")"
actual="$(sha256sum "$tmp/$asset" | cut -d' ' -f1)"
[ -n "$expected" ] && [ "$actual" = "$expected" ] \
  || die "git@gh : empreinte SHA-256 invalide pour $asset, installation annulée"

# The Windows archive has bin/gh.exe at its root; the others put it under
# gh_<version>_<os>_<arch>/bin/.
case $os in
  windows) member="bin/$exe" ;;
  *)       member="$name/bin/$exe" ;;
esac
if [ "$ext" = zip ]; then
  if command -v unzip >/dev/null; then
    unzip -q -o "$tmp/$asset" "$member" -d "$tmp"
  else
    powershell.exe -NoProfile -Command \
      "Expand-Archive -Force -Path '$(cygpath -w "$tmp/$asset")' -DestinationPath '$(cygpath -w "$tmp")'"
  fi
else
  tar -xzf "$tmp/$asset" -C "$tmp" --no-same-owner "$member"
fi

mkdir -p "$BIN_DIR"
mv -f "$tmp/$member" "$BIN_DIR/$exe"
chmod +x "$BIN_DIR/$exe"
info "gh $GH_VERSION installé dans $BIN_DIR/ (empreinte vérifiée)."
if ! "$BIN_DIR/$exe" auth status >/dev/null 2>&1; then
  info "Connexion à GitHub, une fois par poste : $BIN_DIR/$exe auth login"
fi
