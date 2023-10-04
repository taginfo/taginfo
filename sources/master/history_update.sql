-- ============================================================================
--
--  Taginfo
--
--  history_update.sql
--
-- ============================================================================

ATTACH DATABASE 'file:__DIR__/taginfo-master.db?mode=ro' AS master;

INSERT INTO history_stats (udate, key, value) SELECT substr(datetime('now'), 1, 10), key, value FROM master.master_stats;

ANALYZE history_stats;

