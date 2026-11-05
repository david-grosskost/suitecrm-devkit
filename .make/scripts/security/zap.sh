#!/usr/bin/env bash
# Passive scan of a running instance, from outside (OWASP ZAP baseline): ZAP
# browses its public pages for about a minute and reports what it sees
# (security headers, cookies, information leaks, mixed content). Passive:
# nothing is attacked, no data is changed. Without credentials: only what an
# anonymous visitor reaches (login page, public assets).
#
# Fails on a high-risk alert; medium and low ones are listed, never failed.
# An alert accepted on purpose goes in the project's .zap/rules.tsv, one per
# line: <rule id> TAB IGNORE TAB (<reason>).
#
# Report in .tools/zap/ (zap-report.html to read, zap-report.json).
# The weekly workflow of the project (suitecrm-devkit zap.yml) runs it too.
#
# @usage make security@zap URL=https://demo.example.com
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

url="${URL:-}"
[[ $url =~ ^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/[^[:space:]]*)?$ ]] \
  || die "security@zap : URL manquante ou invalide (ex. make security@zap URL=https://demo.example.com)"

out=".tools/zap"
rm -rf "$out"
mkdir -p "$out"
# ZAP runs as its own user in the container: the report directory must be writable by it.
chmod a+rwx "$out"

ignored=()
config=()
if [ -f .zap/rules.tsv ]; then
  cp .zap/rules.tsv "$out/rules.tsv"
  config=(-c rules.tsv)
  while IFS=$'\t' read -r id action _; do
    [ "${action:-}" = IGNORE ] && ignored+=("$id")
  done < <(grep -v '^#' .zap/rules.tsv | tr -d '\r')
fi

# -I: warnings never fail the scan here, the risk levels are judged below.
# Exit status 3 = ZAP itself failed (target unreachable, bad option...).
status=0
run docker run --rm -v "$(host_pwd)/$out:/zap/wrk:rw" "$ZAP_IMAGE" \
  zap-baseline.py -t "$url" -I -J zap-report.json -r zap-report.html "${config[@]}" || status=$?
[ "$status" -ne 3 ] && [ -f "$out/zap-report.json" ] \
  || die "security@zap : le scan n'a pas pu se faire (code $status), voir la sortie ci-dessus"

# Risk of each alert (pluginid, then its riskcode, in the report's order),
# without the rules accepted in .zap/rules.tsv. 3 high, 2 medium, 1 low, 0 info.
high=0 medium=0 low=0
while read -r id risk; do
  for skip in "${ignored[@]}"; do [ "$id" = "$skip" ] && continue 2; done
  case $risk in 3) high=$((high + 1)) ;; 2) medium=$((medium + 1)) ;; 1) low=$((low + 1)) ;; esac
done < <(grep -oE '"(pluginid|riskcode)": *"[0-9]+"' "$out/zap-report.json" \
           | grep -oE '[0-9]+"$' | tr -d '"' | paste - -)

summary="ZAP sur $url : $high élevée(s), $medium moyenne(s), $low faible(s) (acceptées exclues). Rapport : $out/zap-report.html"
info "$summary"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "$summary" >> "$GITHUB_STEP_SUMMARY"
fi
[ "$high" -eq 0 ] || die "security@zap : $high alerte(s) de risque élevé → voir le rapport"
