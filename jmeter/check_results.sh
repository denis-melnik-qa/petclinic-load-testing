#!/usr/bin/env bash
# usage: check_results.sh file.jtl max_p95_ms max_err_pct skip_seconds
set -eu
JTL="$1"; MAX_P95="$2"; MAX_ERR="$3"; SKIP="${4:-0}"
TMP=$(mktemp); LAT=$(mktemp)
awk -F, -v skip="$SKIP" 'NR==1{next} NR==2{t0=$1} $3 !~ /-[0-9]+$/ && ($8=="true"||$8=="false") && ($1-t0)/1000>=skip {print $2, $8}' "$JTL" > "$TMP"
TOTAL=$(wc -l < "$TMP")
[ "$TOTAL" -gt 0 ] || { echo "FAIL: no samples"; exit 1; }
ERR=$(grep -c ' false$' "$TMP" || true)
cut -d' ' -f1 "$TMP" | sort -n > "$LAT"
P95=$(awk -v n="$TOTAL" 'BEGIN{k=int(n*0.95); if(k<n*0.95)k++} NR==k{p=$1} END{print p}' "$LAT")
ERR_PCT=$(awk -v e="$ERR" -v n="$TOTAL" 'BEGIN{printf "%.2f", e*100/n}')
echo "samples=$TOTAL p95=${P95}ms errors=${ERR_PCT}%"
if awk -v p="$P95" -v mp="$MAX_P95" -v er="$ERR_PCT" -v me="$MAX_ERR" 'BEGIN{exit !(p<=mp && er<me)}'; then
  echo "PASS"
else
  echo "FAIL: criteria p95<=${MAX_P95}ms, errors<${MAX_ERR}%"; exit 1
fi
