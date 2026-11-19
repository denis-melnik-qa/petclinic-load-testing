#!/bin/bash
# usage: jmeter/pg_diagnostics.sh label run_dir [interval_seconds=0]
# Appends PostgreSQL counters, top statements and table sizes to files in run_dir. Deletes nothing.
LABEL="${1:-snap}"; DIR="${2:-results}"; EVERY="${3:-0}"
CNT="$DIR/pg-counters.csv"; STM="$DIR/pg-statements.log"
mkdir -p "$DIR"
[ -s "$CNT" ] || echo "epoch,label,blks_hit,blks_read,xact_commit,temp_bytes,ckpt_timed,ckpt_req,buf_checkpoint,buf_backend,dead_tuples" > "$CNT"
Q_CNT="SELECT d.blks_hit, d.blks_read, d.xact_commit, d.temp_bytes, b.checkpoints_timed, b.checkpoints_req, b.buffers_checkpoint, b.buffers_backend, (SELECT coalesce(sum(n_dead_tup),0) FROM pg_stat_user_tables) FROM pg_stat_database d, pg_stat_bgwriter b WHERE d.datname='petclinic';"
Q_STM="SELECT left(regexp_replace(query,'\s+',' ','g'),70) AS query, calls, round(total_exec_time::numeric) AS total_ms, round(mean_exec_time::numeric,2) AS mean_ms, shared_blks_hit AS hit, shared_blks_read AS read FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 8;"
while true; do
  R=$(docker compose exec -T postgres psql -U petclinic -d petclinic -At -F ',' -c "$Q_CNT")
  echo "$(date +%s),$LABEL,$R" >> "$CNT"
  { echo "=== $(date +%H:%M:%S) $LABEL ==="; docker compose exec -T postgres psql -U petclinic -d petclinic -c "$Q_STM"; } >> "$STM"
  jmeter/db_snapshot.sh "$LABEL" "$DIR/db-growth.log"
  [ "$EVERY" -gt 0 ] || break
  sleep "$EVERY"
done
