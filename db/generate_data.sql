BEGIN;

-- Align sequences with existing demo data
SELECT setval(pg_get_serial_sequence('owners','id'), COALESCE((SELECT max(id) FROM owners),1));
SELECT setval(pg_get_serial_sequence('pets','id'), COALESCE((SELECT max(id) FROM pets),1));
SELECT setval(pg_get_serial_sequence('visits','id'), COALESCE((SELECT max(id) FROM visits),1));

-- 100,000 owners with ~900 distinct last names (~110 owners per name)
WITH n AS (
  SELECT
    ARRAY['James','Mary','John','Patricia','Robert','Jennifer','Michael','Linda','William','Elizabeth','David','Susan','Richard','Jessica','Joseph','Sarah','Thomas','Karen','Daniel','Nancy'] AS fn,
    ARRAY['Bar','Car','Dal','Ell','Fer','Gar','Har','Jen','Kel','Lan','Mar','Nel','Ott','Per','Rob','Sam','Tay','Wal','Wil','Ber','Cro','Dav','Fra','Gil','Hol','Hud','Kin','Lew','Mor','Ste'] AS s1,
    ARRAY['ton','son','ley','man','ford','well','ing','ers','wood','field','berg','stone','worth','by','ham','land','den','don','ner','ris','ville','more','shaw','gan','rick','lin','ward','hill','dale','brook'] AS s2,
    ARRAY['Main St','Oak Ave','Pine Rd','Maple Dr','Cedar Ln','Elm St'] AS st,
    ARRAY['Madison','Springfield','Fairview','Salem','Georgetown','Clinton'] AS ct
)
INSERT INTO owners (first_name, last_name, address, city, telephone)
SELECT
  n.fn[1 + floor(random()*cardinality(n.fn))::int],
  n.s1[1 + floor(random()*cardinality(n.s1))::int] || n.s2[1 + floor(random()*cardinality(n.s2))::int],
  (1 + floor(random()*999)::int)::text || ' ' || n.st[1 + floor(random()*cardinality(n.st))::int],
  n.ct[1 + floor(random()*cardinality(n.ct))::int],
  lpad(floor(random()*10000000000)::bigint::text, 10, '0')
FROM n, generate_series(1, 100000) g;

-- ~1.5 pets per new owner.
-- First pet takes a name from list A, second pet from list B.
-- The lists do not overlap, so names never collide within one owner.
WITH n AS (
  SELECT
    ARRAY['Leo','Basil','Rosy','Jewel','Iggy','George','Samantha','Max','Lucky','Mulligan'] AS pa,
    ARRAY['Freddy','Sly','Bella','Charlie','Luna','Milo','Daisy','Rocky','Coco','Buddy'] AS pb,
    (SELECT array_agg(id) FROM types) AS tids
)
INSERT INTO pets (name, birth_date, type_id, owner_id)
SELECT
  CASE WHEN g.k = 1
       THEN n.pa[1 + floor(random()*cardinality(n.pa))::int]
       ELSE n.pb[1 + floor(random()*cardinality(n.pb))::int]
  END,
  DATE '2015-01-01' + floor(random()*3500)::int,
  n.tids[1 + floor(random()*cardinality(n.tids))::int],
  o.id
FROM n, owners o, generate_series(1, 2) AS g(k)
WHERE o.id > 10 AND (g.k = 1 OR random() < 0.5);

-- ~1.3 visits per new pet
WITH n AS (
  SELECT ARRAY['Annual checkup','Vaccination','Dental cleaning','Minor injury','Follow-up visit','Skin condition'] AS d
)
INSERT INTO visits (pet_id, visit_date, description)
SELECT
  p.id,
  DATE '2023-01-01' + floor(random()*1000)::int,
  n.d[1 + floor(random()*cardinality(n.d))::int]
FROM n, pets p, generate_series(1, 2) AS g(k)
WHERE p.owner_id > 10 AND (g.k = 1 OR random() < 0.3);

COMMIT;
ANALYZE;
