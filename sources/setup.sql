--
--  setup.sql
--
--  Set up environment for quick sqlite operations
--

PRAGMA journal_mode  = OFF;
PRAGMA synchronous   = OFF;
PRAGMA temp_store    = MEMORY;
PRAGMA cache_size    = 1000000;

