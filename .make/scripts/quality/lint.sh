#!/usr/bin/env bash
# Checks the code without changing it: Dockerfiles (hadolint), PHP code style
# (PHP-CS-Fixer, dry run) and shell scripts (shellcheck). All checks run, so
# every problem is shown at once. The CI runs the same command.
#
# @usage make quality@lint
set -uo pipefail
. "$(dirname "$0")/../lib.sh"

failed=0

# Dockerfiles tracked by Git. Run from the project directory, so hadolint
# reads the project's .hadolint.yaml if there is one.
while IFS= read -r dockerfile; do
  run docker run --rm -v "$(host_pwd):/app" -w /app "$HADOLINT_IMAGE" \
    hadolint "$dockerfile" || failed=1
done < <(git ls-files '*Dockerfile*')

if [ -f .php-cs-fixer.dist.php ]; then
  php_run vendor/bin/php-cs-fixer fix --dry-run --diff --show-progress=none || failed=1
fi

"$SCRIPTS/git/shellcheck.sh" || failed=1

if [ "$failed" = 0 ]; then
  info "Qualité : aucun problème."
else
  info "Qualité : problèmes à corriger (le style PHP se corrige avec « make quality@fix »)."
fi
exit "$failed"
