#!/bin/bash
# Removes data created by load tests and prints row counts.
docker compose exec -T postgres psql -U petclinic -d petclinic -v ON_ERROR_STOP=1 < db/cleanup_test_data.sql
docker compose exec postgres psql -U petclinic -d petclinic -c "SELECT (SELECT count(*) FROM owners) AS owners, (SELECT count(*) FROM pets) AS pets, (SELECT count(*) FROM visits) AS visits;"
