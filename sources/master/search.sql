-- ============================================================================
--
--  Taginfo
--
--  search.sql
--
-- ============================================================================

ATTACH DATABASE '__DIR__/db/taginfo-db.db' AS db;

DROP TABLE IF EXISTS ftsearch;
CREATE VIRTUAL TABLE ftsearch USING fts5 (
    columnsize=0,
    key,
    value,
    count_all UNINDEXED
);

INSERT INTO ftsearch (key, value, count_all) SELECT key, value, count_all FROM db.tags;

ANALYZE;

