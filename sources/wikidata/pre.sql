--
--  Taginfo source: Wikidata
--
--  pre.sql
--

INSERT INTO source (id, name, update_start, data_until) SELECT 'wikidata', 'Wikidata', datetime('now'), datetime('now');

DROP TABLE IF EXISTS wikidata_keys;

CREATE TABLE wikidata_keys (
    code TEXT,
    key  TEXT
);

DROP TABLE IF EXISTS wikidata_tags;

CREATE TABLE wikidata_tags (
    code  TEXT,
    key   TEXT,
    value TEXT
);

DROP TABLE IF EXISTS wikidata_errors;

CREATE TABLE wikidata_errors (
    wikidata    TEXT,
    item        TEXT,
    code        TEXT,
    propvalue   TEXT,
    description TEXT,
    error       TEXT
);

DROP TABLE IF EXISTS wikidata_labels;

CREATE TABLE wikidata_labels (
    code  TEXT,
    label TEXT,
    lang  TEXT
);

