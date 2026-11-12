# PetClinic Load Testing

Load testing project: Spring PetClinic + PostgreSQL in Docker,
with JMeter, Prometheus and Grafana (work in progress).

## Run
docker compose up --build

App: http://localhost:8080

## Notes
Resource limits (CPU/memory) are applied to the application container to
find the bottleneck reproducibly on a single-machine lab setup. The load
generator shares the host with the system under test, so absolute numbers
are not representative of production hardware; the project demonstrates
the methodology.

Test machine: 6 GB RAM, everything (system under test, monitoring and load
generator) runs on a single host. Grafana alerting is disabled to save memory.
