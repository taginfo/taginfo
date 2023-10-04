-- ============================================================================
--
--  Taginfo
--
--  master-chronology.sql
--
-- ============================================================================

ATTACH DATABASE 'file:__DIR__/chronology/taginfo-chronology.db?mode=ro' AS chronology;

-- ============================================================================

INSERT INTO sources SELECT 5, 1, * FROM chronology.source;

INSERT INTO master_stats SELECT * FROM chronology.stats;

