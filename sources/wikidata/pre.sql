--
--  Taginfo source: Wikidata
--
--  pre.sql
--

INSERT INTO source (id, name, update_start, data_until) SELECT 'wikidata', 'Wikidata', datetime('now'), datetime('now');

DROP TABLE IF EXISTS wikidata_p1282;

CREATE TABLE wikidata_p1282 (
    item          TEXT,
    propvalue     TEXT,
    ptype         TEXT,
    key           TEXT,
    value         TEXT,
    relation_type TEXT,
    relation_role TEXT
);

DROP TABLE IF EXISTS wikidata_p1282_errors;

CREATE TABLE wikidata_p1282_errors (
    item          TEXT,
    propvalue     TEXT,
    description   TEXT,
    error         TEXT
);

DROP TABLE IF EXISTS wikidata_labels;

CREATE TABLE wikidata_labels (
    item  TEXT,
    label TEXT,
    lang  TEXT
);

