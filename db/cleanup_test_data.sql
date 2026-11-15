BEGIN;
DELETE FROM visits WHERE description IN ('Test Visit','Load test visit');
DELETE FROM visits WHERE pet_id IN (SELECT id FROM pets WHERE owner_id IN (SELECT id FROM owners WHERE last_name LIKE 'LT%'));
DELETE FROM pets WHERE owner_id IN (SELECT id FROM owners WHERE last_name LIKE 'LT%');
DELETE FROM owners WHERE last_name LIKE 'LT%';
COMMIT;
ANALYZE;
