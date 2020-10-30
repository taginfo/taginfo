--
--  Taginfo source: Languages
--
--  pre.sql
--

INSERT INTO source (id, name, update_start, data_until) SELECT 'languages', 'Languages', datetime('now'), datetime('now');

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

DROP TABLE IF EXISTS unicode_scripts;

CREATE TABLE unicode_scripts (
    script TEXT,
    name   TEXT
);

DROP TABLE IF EXISTS unicode_codepoint_script_mapping;

CREATE TABLE unicode_codepoint_script_mapping (
    codepoint_from TEXT,
    codepoint_to   TEXT,
    name           TEXT
);

DROP TABLE IF EXISTS wikipedia_sites;

CREATE TABLE wikipedia_sites (
    prefix   TEXT,
    language TEXT
);

