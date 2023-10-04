-- ============================================================================
--
--  Taginfo
--
--  selection.sql
--
--  This database contains a selection of often used tags etc.
--
--  It is used in the next taginfo run to create some statistics, maps, etc.
--  only for those selected data.
--
-- ============================================================================

ATTACH DATABASE 'file:__DIR__/db/taginfo-db.db?mode=ro'     AS db;
ATTACH DATABASE 'file:__DIR__/wiki/taginfo-wiki.db?mode=ro' AS wiki;

-- ============================================================================

DROP TABLE IF EXISTS interesting_tags;
CREATE TABLE interesting_tags (
    key   TEXT,
    value TEXT
);

-- MIN_COUNT_TAGS setting: sources.master.min_count_tags
INSERT INTO interesting_tags (key, value)
    SELECT DISTINCT key, NULL FROM db.keys WHERE count_all > __MIN_COUNT_TAGS__
    UNION
    SELECT key, value FROM db.tags WHERE count_all > __MIN_COUNT_TAGS__;

-- DELETE FROM interesting_tags WHERE key IN ('created_by', 'ele', 'height', 'is_in', 'lanes', 'layer', 'maxspeed', 'name', 'ref', 'width') AND value IS NOT NULL;
-- DELETE FROM interesting_tags WHERE value IS NOT NULL AND key LIKE '%:%';
-- DELETE FROM interesting_tags WHERE value IS NOT NULL AND key LIKE 'fresno_%';

ANALYZE interesting_tags;

-- ============================================================================

DROP TABLE IF EXISTS frequent_tags;
CREATE TABLE frequent_tags (
    key   TEXT,
    value TEXT
);

-- MIN_COUNT_FOR_MAP setting: sources.master.min_count_for_map
INSERT INTO frequent_tags (key, value) SELECT key, value FROM db.tags WHERE count_all > __MIN_COUNT_FOR_MAP__;

ANALYZE frequent_tags;

-- ============================================================================

DROP TABLE IF EXISTS interesting_relation_types;
CREATE TABLE interesting_relation_types (
    rtype TEXT
);

-- MIN_COUNT_RELATIONS_PER_TYPE setting: sources.master.min_count_relations_per_type
INSERT INTO interesting_relation_types (rtype)
    SELECT value FROM db.tags WHERE key='type' AND count_relations > __MIN_COUNT_RELATIONS_PER_TYPE__;

ANALYZE interesting_relation_types;

-- ============================================================================
