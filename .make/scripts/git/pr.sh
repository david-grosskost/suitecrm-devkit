#!/usr/bin/env bash
# Pushes the current branch and opens its pull request on GitHub, titled
# after the branch's first commit (gh pr create --fill-first): a Conventional
# Commits title even when the branch has several commits, where GitHub would
# propose the branch name, refused by checks / commit-msg. If the branch
# already has a pull request, pushes and shows its address.
# Needs gh (make git@gh), signed in once: .tools/bin/gh auth login.
#
# @usage make git@pr
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

branch="$(git rev-parse --abbrev-ref HEAD)"
base="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
base="${base:-main}"
[ "$branch" != HEAD ] || die "git@pr : aucune branche (HEAD détachée)"
[ "$branch" != "$base" ] || die "git@pr : on est sur $base ; créer d'abord une branche de travail"
[ -n "$(git log --oneline "origin/$base..HEAD" 2>/dev/null)" ] \
  || die "git@pr : aucun commit sur $branch par rapport à origin/$base"
[ -z "$(git status --porcelain)" ] \
  || info "Attention : des changements ne sont pas commités, ils ne seront pas dans la PR."

gh="$(tool gh)" || die "git@pr : gh introuvable ; l'installer avec make git@gh"
"$gh" auth status >/dev/null 2>&1 \
  || die "git@pr : gh n'est pas connecté à GitHub ; lancer une fois $gh auth login"

run git push -u origin "$branch"

if url="$("$gh" pr view "$branch" --json url --jq .url 2>/dev/null)" && [ -n "$url" ]; then
  info "PR déjà ouverte : $url"
  exit 0
fi
run "$gh" pr create --base "$base" --head "$branch" --fill-first
