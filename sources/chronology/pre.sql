--
--  Taginfo source: Chronology
--
--  pre.sql
--

INSERT INTO source (id, name, update_start) SELECT 'chronology', 'Chronology', datetime('now');

DROP TABLE IF EXISTS keys_chronology;

CREATE TABLE keys_chronology (
    key  TEXT,
    data BLOB
);

DROP TABLE IF EXISTS tags_chronology;

CREATE TABLE tags_chronology (
    key   TEXT,
    value TEXT,
    data  BLOB
);

