--
--  Taginfo source: Wiki
--
--  pre.sql
--

.bail ON

INSERT INTO source (id, name, update_start, data_until) SELECT 'wiki', 'Wiki', datetime('now'), datetime('now');

DROP TABLE IF EXISTS wikipages;

CREATE TABLE wikipages (
    lang             TEXT,
    tag              TEXT,
    key              TEXT,
    value            TEXT,
    title            TEXT,
    body             TEXT,
    tgroup           TEXT,
    type             TEXT,
    has_templ        INTEGER,
    parsed           INTEGER,
    description      TEXT,
    image            TEXT,
    on_node          INTEGER,
    on_way           INTEGER,
    on_area          INTEGER,
    on_relation      INTEGER,
    tags_implies     TEXT,
    tags_combination TEXT,
    tags_linked      TEXT,
    status           TEXT
);

DROP TABLE IF EXISTS wikipages_keys;

CREATE TABLE wikipages_keys (
    key        TEXT,
    langs      TEXT,
    lang_count INTEGER
);

DROP TABLE IF EXISTS wikipages_tags;

CREATE TABLE wikipages_tags (
    key        TEXT,
    value      TEXT,
    langs      TEXT,
    lang_count INTEGER
);

DROP TABLE IF EXISTS wiki_languages;

CREATE TABLE wiki_languages (
    language    TEXT,
    count_pages INTEGER
);

DROP TABLE IF EXISTS invalid_page_title;

CREATE TABLE invalid_page_titles (
    reason TEXT,
    title  TEXT
);

DROP TABLE IF EXISTS words;

CREATE TABLE words (
    key   TEXT,
    value TEXT,
    words TEXT
);

DROP TABLE IF EXISTS stats;

CREATE TABLE stats (
    key   TEXT,
    value INT64
);

