#!/bin/bash
# usage: jmeter/db_snapshot.sh label out_log [repeat_every_seconds]
# Appends row counts and table sizes to the log. Deletes nothing.
LABEL="${1:-snapshot}"; LOG="${2:-results/db-growth.log}"; EVERY="${3:-0}"
Q="SELECT (SELECT count(*) FROM owners), (SELECT count(*) FROM visits), pg_size_pretty(pg_total_relation_size('owners')), pg_size_pretty(pg_total_relation_size('visits')), pg_size_pretty(pg_database_size('petclinic'));"
[ -s "$LOG" ] || echo "time | label | owners | visits | owners_size | visits_size | db_size" >> "$LOG"
while true; do
  R=$(docker compose exec -T postgres psql -U petclinic -d petclinic -At -F ' | ' -c "$Q")
  echo "$(date +%H:%M:%S) | $LABEL | $R" >> "$LOG"
  [ "$EVERY" -gt 0 ] || break
  sleep "$EVERY"
done
