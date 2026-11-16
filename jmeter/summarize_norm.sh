#!/bin/bash
# usage: summarize_norm.sh file.jtl window_sec skip_sec
f=$1; w=$2; skip=$3
awk -F, -v w="$w" -v skip="$skip" 'NR==1{next} NR==2{t0=$1} {
  l=$3; if (l ~ /-[0-9]+$/) next;
  gsub(/\/[0-9]+/,"/{id}",l);
  s=($1-t0)/1000; if (s<skip) next;
  print int((s-skip)/w) "|" l "|" $2 "|" ($8=="true"?0:1)
}' "$f" | sort -t'|' -k1,1n -k2,2 -k3,3n | awk -F'|' '
function flush(  i){ if(n){ i=int(0.95*n); if(i<0.95*n)i++; if(i<1)i=1;
  printf "%-3s %-42s %7d %7.0f %7d %7d %6.2f\n", pw, pl, n, sum/n, v[i], v[n], 100*e/n } }
BEGIN{print "win label                                      count  avg_ms  p95_ms  max_ms  err_%"}
{ if($1!=pw||$2!=pl){flush(); pw=$1; pl=$2; n=0; sum=0; e=0}
  n++; v[n]=$3; sum+=$3; e+=$4 }
END{flush()}'
