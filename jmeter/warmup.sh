#!/bin/bash
# Warm-up before a test: JIT, connection pool, caches. Takes about 1-2 minutes.
TERM_=$(head -1 jmeter/data/search_terms.csv)
for i in $(seq 1 150); do
  curl -s -o /dev/null "localhost:8080/owners?lastName=$TERM_"
  curl -s -o /dev/null "localhost:8080/owners/1"
  curl -s -o /dev/null "localhost:8080/vets.html"
done
echo "warm-up done"
