-- ============================================================================
--
--  Taginfo
--
--  master-wikidata.sql
--
-- ============================================================================

ATTACH DATABASE '__DIR__/wikidata/taginfo-wikidata.db' AS wikidata;

-- ============================================================================

INSERT INTO sources SELECT 6, 1, * FROM wikidata.source;

INSERT INTO master_stats SELECT * FROM wikidata.stats;

