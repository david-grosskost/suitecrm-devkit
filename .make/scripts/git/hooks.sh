#!/usr/bin/env bash
# Enables the versioned Git hooks of the devkit and installs the tools they
# use (gitleaks, shellcheck). The hooks live in the devkit: in a project, Git
# is pointed at vendor/david-grosskost/suitecrm-devkit/.githooks.
# Once per clone; app@install runs it in local.
#
# @usage make git@hooks
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

git rev-parse --git-dir >/dev/null 2>&1 \
  || die "git@hooks : ce dossier n'est pas un dépôt Git"

run git config core.hooksPath "$(devkit_dir)/.githooks"
"$SCRIPTS/git/gitleaks.sh"
"$SCRIPTS/git/shellcheck.sh"
info "Hooks Git activés : messages de commit, scripts, fichiers sensibles et secrets vérifiés."
