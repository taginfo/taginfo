--
--  add_ftsearch.sql
--
--  Add indexes for full text search.
--
--  These indexes will be added AFTER the taginfo-db.db is made available for
--  download to keep the download to a reasonable size.
--

DROP TABLE IF EXISTS ftsearch;

CREATE VIRTUAL TABLE ftsearch USING fts5 (
    content='tags',
    key,
    value,
    count_all UNINDEXED,
);

-- Building the index is much faster with larger cache size
PRAGMA cache_size = 1000000;

INSERT INTO ftsearch (key, value, count_all) SELECT key, value, count_all FROM tags;
ANALYZE ftsearch;

