--
--  init.sql
--
--  Initialize source database
--

--
-- Contains metadata about this source.
--
DROP TABLE IF EXISTS source;
CREATE TABLE source (
    id           TEXT,
    name         TEXT,
    update_start TEXT,
    update_end   TEXT,
    data_until   TEXT
);

--
-- Contains general statistical data for this source.
--
DROP TABLE IF EXISTS stats;
CREATE TABLE stats (
    key   TEXT,
    value INT64
);

