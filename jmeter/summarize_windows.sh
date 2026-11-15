#!/bin/bash
# usage: jmeter/summarize_windows.sh file.jtl [step_seconds=180] [skip_seconds=30]
F="$1"; STEP="${2:-180}"; SKIP="${3:-30}"
awk -F, -v step="$STEP" -v skip="$SKIP" 'NR>1 && ($8=="true"||$8=="false") {
  if (!t0) t0=$1
  off=($1-t0)/1000; w=int(off/step)
  if (off - w*step >= skip) print w, $2, ($8=="false"?1:0), $1, $13
}' "$F" > /tmp/win_rows.txt
printf "%-5s %-6s %8s %8s %8s %8s %7s\n" step users req/s avg_ms p95_ms p99_ms err_%
for W in $(awk '{print $1}' /tmp/win_rows.txt | sort -n | uniq); do
  awk -v w="$W" '$1==w' /tmp/win_rows.txt > /tmp/w.txt
  N=$(wc -l < /tmp/w.txt)
  awk '{print $2}' /tmp/w.txt | sort -n > /tmp/lat.txt
  AVG=$(awk '{s+=$1} END {printf "%.0f", s/NR}' /tmp/lat.txt)
  P95=$(awk -v n="$N" 'BEGIN{i=int(n*0.95)+1; if(i>n)i=n} NR==i {print; exit}' /tmp/lat.txt)
  P99=$(awk -v n="$N" 'BEGIN{i=int(n*0.99)+1; if(i>n)i=n} NR==i {print; exit}' /tmp/lat.txt)
  ERR=$(awk '{e+=$3} END {printf "%.2f", 100*e/NR}' /tmp/w.txt)
  USERS=$(awk '{if($5>m)m=$5} END {print m}' /tmp/w.txt)
  DUR=$(awk 'NR==1{mn=$4;mx=$4} {if($4<mn)mn=$4; if($4>mx)mx=$4} END {print (mx-mn)/1000}' /tmp/w.txt)
  RPS=$(awk -v n="$N" -v d="$DUR" 'BEGIN{if(d>0) printf "%.1f", n/d; else print "n/a"}')
  printf "%-5s %-6s %8s %8s %8s %8s %7s\n" "$((W+1))" "$USERS" "$RPS" "$AVG" "$P95" "$P99" "$ERR"
done
