#!/usr/bin/env bash
# Runs the package scanner of SuiteCRM's Module Loader on the package of an
# extension (make package@build first), as an instance with the scan on would
# (moduleInstaller.packageScan): fails on the first file it refuses. The
# scanner is SuiteCRM's own code, the version the extensions are built
# against: downloaded from SuiteCRM-Core on GitHub into .tools/ (AGPL, not
# copied into the devkit), checked against its SHA-256.
# A project without extension.json (not an extension) is skipped.
#
# @usage make package@scan
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

if [ ! -f extension.json ]; then
  info "package@scan : pas de extension.json, ce projet n'est pas une extension."
  exit 0
fi

# SHA-256 of the scanner's two files, for each version of SuiteCRM it is used
# with: a new version of SuiteCRM adds its line here.
case "$SUITECRM_VERSION" in
  8.10.2)
    scanner_sha=b5c25908fffa64f3133557cf5c00963c1cf6f03e19029fc42e92427ddb0272c1
    visitor_sha=2f426de81ae93807d50b7b427e139bb9bae76c6053a86b441e0b28a1aa9fde44 ;;
  *) die "package@scan : empreintes du scanner inconnues pour SuiteCRM $SUITECRM_VERSION (scan.sh)" ;;
esac

dir=".tools/suitecrm-scanner/$SUITECRM_VERSION"
source="https://raw.githubusercontent.com/SuiteCRM/SuiteCRM-Core/v$SUITECRM_VERSION/public/legacy/ModuleInstall"
mkdir -p "$dir"
for file in ModuleScanner.php:$scanner_sha ModuleScannerVisitor.php:$visitor_sha; do
  name="${file%%:*}"
  sha="${file#*:}"
  if [ ! -f "$dir/$name" ] || [ "$(sha256sum "$dir/$name" | cut -d' ' -f1)" != "$sha" ]; then
    run curl -sSfL -o "$dir/$name.new" "$source/$name"
    [ "$(sha256sum "$dir/$name.new" | cut -d' ' -f1)" = "$sha" ] \
      || { rm -f "$dir/$name.new"; die "package@scan : empreinte SHA-256 invalide pour $name, scan annulé"; }
    mv "$dir/$name.new" "$dir/$name"
  fi
done

# The package of the highest version in build/ (older ones may stay there).
shopt -s nullglob
packages=(build/*.zip)
[ ${#packages[@]} -gt 0 ] || die "package@scan : aucun paquet dans build/, lancer d'abord make package@build"
package="$(printf '%s\n' "${packages[@]}" | sort -V | tail -n 1)"

php_run "$(devkit_dir)/.make/scripts/package/scan.php" "$dir" "$package"
