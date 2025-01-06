-- ============================================================================
--
--  Taginfo
--
--  master-sw.sql
--
-- ============================================================================

ATTACH DATABASE 'file:__DIR__/sw/taginfo-sw.db?mode=ro' AS sw;

-- ============================================================================

INSERT INTO sources SELECT 7, 1, * FROM sw.source;

INSERT INTO master_stats SELECT * FROM sw.stats;

