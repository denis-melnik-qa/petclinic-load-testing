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

**Confirmation:** a 10-minute run at 70 users (after 60s ramp-up):
167 req/s, avg 310ms, p95 851ms, p99 1304ms, 0% errors.

**Findings**
- Bottleneck: the application and the database together consume about 180% of the 2 CPU cores available to Docker, starting from 40 users. This is a combined figure (app + DB), observed in Grafana, not a JMeter metric. The limit is therefore the CPU of the whole host.
- Slowest request: the search by last name (GET /owners).
- req/s are JMeter counts. The server sees about 1.4× more requests because of redirects after POST. This explains the difference from Grafana's request rate (e.g. 157 × 1.4 ≈ 220).

**Notes:** req/s are JMeter counts (the server sees about 1.4x more requests because of redirects after POST). Everything (application, database, monitoring and the load generator) runs on one machine with 6 GB RAM, so absolute numbers are not representative of production hardware; the project demonstrates the methodology. Maximum response times of 7-11 s in the raw data are one-off stalls of the whole host, so percentiles are used instead.
