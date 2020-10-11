--
--  add_extra_indexes.sql
--
--  Add extra indexes to improve web interface performance.
--
--  These indexes will be added AFTER the taginfo-db.db is made available for
--  download to keep the download to a reasonable size.
--

CREATE INDEX tags_key_count_nodes_idx     ON tags (key, count_nodes     DESC);
ANALYZE tags_key_count_nodes_idx;

CREATE INDEX tags_key_count_ways_idx      ON tags (key, count_ways      DESC);
ANALYZE tags_key_count_ways_idx;

CREATE INDEX tags_key_count_relations_idx ON tags (key, count_relations DESC);
ANALYZE tags_key_count_relations_idx;

CREATE UNIQUE INDEX tags_key_value_idx ON tags (key, value);
ANALYZE tags_key_value_idx;

