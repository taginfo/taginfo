-- ============================================================================
--
--  Taginfo
--
--  search.sql
--
-- ============================================================================

.bail ON

ATTACH DATABASE '__DIR__/db/taginfo-db.db' AS db;

DROP TABLE IF EXISTS ftsearch;
CREATE VIRTUAL TABLE ftsearch USING fts3 (
    key       TEXT,
    value     TEXT,
    count_all INTEGER
);

INSERT INTO ftsearch (key, value, count_all) SELECT key, value, count_all FROM db.tags;

ANALYZE;

