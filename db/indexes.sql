-- Index for "find owners by last name" (LIKE 'prefix%' needs text_pattern_ops
-- unless the database collation is "C").
CREATE INDEX IF NOT EXISTS idx_owners_last_name_pattern ON owners (last_name text_pattern_ops);
ANALYZE owners;
