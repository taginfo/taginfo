-- ============================================================================
--
--  Taginfo
--
--  master-wikidata.sql
--
-- ============================================================================

ATTACH DATABASE 'file:__DIR__/wikidata/taginfo-wikidata.db?mode=ro' AS wikidata;

-- ============================================================================

INSERT INTO sources SELECT 6, 1, * FROM wikidata.source;

INSERT INTO master_stats SELECT * FROM wikidata.stats;

