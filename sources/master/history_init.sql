-- ============================================================================
--
--  Taginfo
--
--  history_init.sql
--
-- ============================================================================

DROP TABLE IF EXISTS history_stats;
CREATE TABLE history_stats (
    udate TEXT,
    key   TEXT,
    value INT64
);

