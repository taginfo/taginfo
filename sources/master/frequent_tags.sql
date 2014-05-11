-- ============================================================================
--
--  Taginfo
--
--  frequent_tags.sql
--
-- ============================================================================

.bail ON

ATTACH DATABASE '__DIR__/db/taginfo-db.db'                 AS db;

-- ============================================================================

DROP TABLE IF EXISTS frequent_tags;
CREATE TABLE frequent_tags (
    key   TEXT,
    value TEXT
);

-- MIN_COUNT_FOR_MAP setting: sources.master.min_count_for_map
INSERT INTO frequent_tags (key, value) SELECT key, value FROM db.tags WHERE count_all > __MIN_COUNT_FOR_MAP__;

ANALYZE frequent_tags;

.output __DIR__/db/frequent_tags.lst

SELECT key || '=' || value FROM frequent_tags ORDER BY key, value;

-- ============================================================================
