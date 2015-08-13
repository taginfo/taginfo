--
--  add_extra_indexes.sql
--
--  Add extra indexes to improve web interface performance.
--
--  These indexes will be added AFTER the taginfo-db.db is made available for
--  download to keep the download to a reasonable size.
--

.bail ON

PRAGMA journal_mode  = OFF;
PRAGMA synchronous   = OFF;
PRAGMA temp_store    = MEMORY;
PRAGMA cache_size    = 5000000;

CREATE INDEX tags_key_count_all_idx       ON tags (key, count_all       DESC);
CREATE INDEX tags_key_count_nodes_idx     ON tags (key, count_nodes     DESC);
CREATE INDEX tags_key_count_ways_idx      ON tags (key, count_ways      DESC);
CREATE INDEX tags_key_count_relations_idx ON tags (key, count_relations DESC);

CREATE UNIQUE INDEX tags_key_value_idx ON tags (key, value);

