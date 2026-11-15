#!/bin/bash
# usage: jmeter/record_stats.sh out.csv   (stop with Ctrl+C)
OUT="${1:-results/docker-stats.csv}"
echo "time,container,cpu_percent,mem_usage" > "$OUT"
while true; do
  docker stats --no-stream --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}}" | sed "s/^/$(date +%H:%M:%S),/" >> "$OUT"
  sleep 30
done
