-- ============================================================================
--
--  Taginfo
--
--  search.sql
--
-- ============================================================================

.bail ON

PRAGMA journal_mode  = OFF;
PRAGMA synchronous   = OFF;
PRAGMA temp_store    = MEMORY;
PRAGMA cache_size    = 5000000;

ATTACH DATABASE '__DIR__/db/taginfo-db.db' AS db;

DROP TABLE IF EXISTS ftsearch;
CREATE VIRTUAL TABLE ftsearch USING fts3 (
    tokenize=__TOKENIZER__,
    key       TEXT,
    value     TEXT,
    count_all INTEGER
);

INSERT INTO ftsearch (key, value, count_all) SELECT key, value, count_all FROM db.tags;

ANALYZE;

