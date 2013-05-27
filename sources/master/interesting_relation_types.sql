-- ============================================================================
--
--  Taginfo
--
--  interesting_relation_types.sql
--
-- ============================================================================

.bail ON

ATTACH DATABASE '__DIR__/db/taginfo-db.db' AS db;

-- ============================================================================

DROP TABLE IF EXISTS interesting_relation_types;
CREATE TABLE interesting_relation_types (
    rtype TEXT
);

-- MIN_COUNT_RELATIONS_PER_TYPE setting: sources.master.min_count_relations_per_type
INSERT INTO interesting_relation_types (rtype)
    SELECT value FROM db.tags WHERE key='type' AND count_relations > __MIN_COUNT_RELATIONS_PER_TYPE__;

ANALYZE interesting_relation_types;

.output __DIR__/db/interesting_relation_types.lst

SELECT rtype FROM interesting_relation_types ORDER BY rtype;

-- ============================================================================
