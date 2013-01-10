--
--  Taginfo source: Languages
--
--  pre.sql
--

.bail ON

INSERT INTO source (id, name, update_start) SELECT 'languages', 'Languages', datetime('now');

DROP TABLE IF EXISTS subtags;

CREATE TABLE subtags (
    stype           TEXT,
    subtag          TEXT,
    added           TEXT,
    suppress_script TEXT,
    scope           TEXT,
    description     TEXT,
    prefix          TEXT
);

