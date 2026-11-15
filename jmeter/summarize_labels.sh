#!/bin/bash
# usage: jmeter/summarize_labels.sh file.jtl from_sec to_sec
# Per-request statistics for the window [from_sec, to_sec), counted from the first sample.
F="$1"; FROM="${2:-0}"; TO="${3:-1000000}"
awk -F, -v from="$FROM" -v to="$TO" 'NR>1 && ($8=="true"||$8=="false") {
  if (!t0) t0=$1
  off=($1-t0)/1000
  if (off>=from && off<to) { l=$3; gsub(/ /,"_",l); print l, $2, ($8=="false"?1:0) }
}' "$F" > /tmp/lab_rows.txt
printf "%-32s %7s %8s %8s %8s %7s\n" request count avg_ms p95_ms max_ms err_%
for L in $(awk '{print $1}' /tmp/lab_rows.txt | sort -u); do
  awk -v l="$L" '$1==l {print $2}' /tmp/lab_rows.txt | sort -n > /tmp/lab_lat.txt
  N=$(wc -l < /tmp/lab_lat.txt)
  AVG=$(awk '{s+=$1} END {printf "%.0f", s/NR}' /tmp/lab_lat.txt)
  P95=$(awk -v n="$N" 'BEGIN{i=int(n*0.95)+1; if(i>n)i=n} NR==i {print; exit}' /tmp/lab_lat.txt)
  MAX=$(tail -1 /tmp/lab_lat.txt)
  ERR=$(awk -v l="$L" '$1==l {e+=$3; c++} END {printf "%.2f", 100*e/c}' /tmp/lab_rows.txt)
  printf "%-32s %7s %8s %8s %8s %7s\n" "$L" "$N" "$AVG" "$P95" "$MAX" "$ERR"
done
