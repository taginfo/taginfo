--
--  Taginfo source: Database
--
--  post_indexes.sql
--

.bail ON

PRAGMA journal_mode  = OFF;
PRAGMA synchronous   = OFF;
PRAGMA temp_store    = MEMORY;
PRAGMA cache_size    = 1000000;

-- ============================================================================

CREATE        INDEX tags_key_count_all_idx ON tags (key, count_all DESC);

CREATE        INDEX key_combinations_key1_idx ON key_combinations (key1);
CREATE        INDEX key_combinations_key2_idx ON key_combinations (key2);
CREATE UNIQUE INDEX key_distributions_key_idx ON key_distributions (key, object_type);

CREATE UNIQUE INDEX tag_distributions_key_value_idx ON tag_distributions (key, value, object_type);

CREATE        INDEX tag_combinations_key1_value1_idx ON tag_combinations (key1, value1);
CREATE        INDEX tag_combinations_key2_value2_idx ON tag_combinations (key2, value2);

CREATE UNIQUE INDEX relation_types_rtype_idx ON relation_types (rtype);
CREATE        INDEX relation_roles_rtype_idx ON relation_roles (rtype);

