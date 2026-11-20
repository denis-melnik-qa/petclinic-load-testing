# PetClinic Load Testing

Load testing project: Spring PetClinic + PostgreSQL in Docker, with JMeter, Prometheus and Grafana (work in progress).

## Run
docker compose up --build

App: http://localhost:8080

## Notes
Resource limits (CPU/memory) are applied to the application container to find the bottleneck reproducibly on a single-machine lab setup. The load generator shares the host with the system under test, so absolute numbers are not representative of production hardware; the project demonstrates the methodology.

Test machine: 6 GB RAM, everything (system under test, monitoring and load generator) runs on a single host. Grafana alerting is disabled to save memory.

## Capacity test (step load)

Acceptance criteria: p95 response time <= 1000ms and errors < 1%.
Load model: closed (fixed number of users), 100ms think time between requests, 5 requests per iteration (search by last name, view owner, list vets, create owner, add visit). Steps of 10 users, each 30s ramp-up + 180s hold, from 10 to 100 users.

| Users | req/s | avg, ms | p95, ms | p99, ms | errors |
|------:|------:|--------:|--------:|--------:|-------:|
| 10    | 63.5  | 50      | 141     | 241     | 0%     |
| 20    | 114.4 | 68      | 175     | 261     | 0%     |
| 30    | 140.4 | 106     | 240     | 347     | 0%     |
| 40    | 153.1 | 154     | 391     | 568     | 0%     |
| 50    | 155.7 | 213     | 534     | 780     | 0%     |
| 60    | 157.3 | 274     | 720     | 1049    | 0%     |
| 70    | 154.6 | 345     | 952     | 1449    | 0%     |
| 80    | 146.3 | 440     | 1216    | 1879    | 0%     |
| 90    | 135.6 | 555     | 1459    | 2077    | 0%     |
| 100   | 132.1 | 650     | 1696    | 2517    | 0%     |

**Result:** maximum load meeting the criteria is about 70 users; the first step that violates them is 80 users. Throughput peaks at 157 req/s around 60 users and declines afterwards (146 req/s at 80 users, 132 req/s at 100 users), while response times grow due to queueing (no errors).

**Confirmation:** a separate 10-minute run at 70 users (after 60s ramp-up):
167 req/s, avg 310ms, p95 851ms, p99 1304ms, 0% errors.
Within this confirmation run, the slowest request is the search by last name (GET /owners): it alone exceeds 1s at p95 (1176ms), while the overall p95 is 851ms because the other requests are faster.

**Findings**
- Bottleneck: the application and the database together consume about 180% of the 2 CPU cores available to Docker, starting from 40 users. This is a combined figure (app + DB), observed in Grafana, not a JMeter metric. The limit is therefore the CPU of the whole host.
- Slowest request: the search by last name (GET /owners).
- req/s are JMeter counts. The server sees about 1.4× more requests because of redirects after POST. This explains the difference from Grafana's request rate (157 * 1.4 ≈ 220).

## Stability (soak) test

**Goal:** check that the system keeps steady response times and does not leak resources under a constant load below the maximum.

**Load:** 56 users (80% of the 70-user maximum), 2 hours, 60s ramp-up, 100 ms think time. Same scenario as in the capacity test. Before the run the test data was removed and the application was warmed up.

**Data growth:** test data was deliberately not cleaned during the run, so the database grew (see below). To separate a resource problem from an effect of data growth, `GET /vets.html` is used as a control request: it does not depend on the size of the `owners` table.

**Acceptance criteria (defined before the run):**
1. Errors < 1%.
2. No container restarts or OOM kills.
3. Control request (`GET /vets.html`): p95 of the last 30 minutes within 15% of
   the first 30 minutes.
4. JVM heap minimums and the HikariCP `pending` metric do not grow over time.
5. Growth of data-dependent requests (`GET /owners`, POST requests) is
   reported, but is not an acceptance criterion.

**Monitored:** Grafana (response time, JVM heap, HikariCP pool, PostgreSQL
connections), container CPU and memory every 30s, table sizes every 10 minutes.

## Index experiment (search by last name)

**Why:** the soak test showed a steady degradation (throughput fell by about
30% at constant load), and `pg_stat_statements` showed that one query, the
count query of the owner search (`last_name LIKE 'prefix%'`), took about 90-95%
of the database time and its cost grew with the table size (average 66 ms over
the 2-hour run; about 2,100 buffer reads per call vs about 1,000 at the start).
Cache hit ratio was ~100%, checkpoints were regular and autovacuum kept up,
so memory and disk were ruled out.

**Plan (before):** `Parallel Seq Scan on owners o` (cost=4900.73..4900.74 rows=1)
(actual time=17.630..17.631 rows=1 loops=3), `Rows Removed by Filter: 105290`,
`Buffers: shared hit=3252`, **Execution Time: 22.921 ms**.
**Plan (after):** `Index Scan using idx_owners_last_name_pattern on owners o`
(cost=0.42..8.44 rows=30) (actual time=0.044..0.313 rows=106 loops=1),
`Index Cond: ((last_name ~>=~ 'Lanris') AND (last_name ~<~ 'Lanrit'))`,
`Buffers: shared hit=103 read=3`, **Execution Time: 0.363 ms**.

**Change:** `CREATE INDEX idx_owners_last_name_pattern ON owners (last_name text_pattern_ops);`
(`text_pattern_ops` is needed for `LIKE 'prefix%'` unless the collation is "C".)
See `db/indexes.sql`.

**Comparison:** two ~2-hour soak runs at 56 users on the same starting data (about 100k owners / 200k visits after `db/cleanup.sh`), browser closed, cleaned and warmed up before each, `pg_stat_statements` reset before each. The "after" run faced a larger table (403k owners by the end vs 316k in the "before" run) and still did better.

| | Without index | With index |
|---|---:|---:|
| req/s, first 10-min window | 167.4 | 206.5 |
| req/s, last 10-min window | 122.8 | 206.8 |
| avg, first → last, ms | 230 → 352 | 167 → 166 |
| p95, first → last, ms | 606 → 789 | 427 → 433 |
| p99, first → last, ms | 879 → 1154 | 747 → 607 |
| GET /owners p95, ms (first → last) | 783 → 792 | 520 → 523 |
| count query, mean ms | 66.44 | 0.14 |
| count query, total DB time | 14 217 s | 42.9 s |
| count query, buffers per call | ~2 138 | ~108 |

**Caveats:** one run per variant (the run without the index went first), so the JMeter percentages are indicative; the database-side numbers are the main evidence. `GET /owners` is still the slowest request (avg 247 ms in the indexed soak) although the database now spends about 0.14 ms on it: the remaining time is most likely spent in the application and in waiting for CPU on the shared machine (hypothesis, not verified). The two soak runs are not perfectly matched — the "after" run lasted 127 min vs 139 min and the table grew further during it.
