--
--  Taginfo source: Wiki
--
--  pre.sql
--

.bail ON

DROP TABLE IF EXISTS meta;

CREATE TABLE meta (
    source_id    TEXT,
    source_name  TEXT,
    update_start TEXT,
    update_end   TEXT,
    data_until   TEXT
);

INSERT INTO meta (source_id, source_name, update_start, data_until) SELECT 'wiki', 'Wiki', datetime('now'), datetime('now');

DROP TABLE IF EXISTS stats;

CREATE TABLE stats (
    key   TEXT,
    value INT64
);

DROP TABLE IF EXISTS wikipages;

CREATE TABLE wikipages (
    lang             VARCHAR,
    tag              VARCHAR,
    key              VARCHAR,
    value            VARCHAR,
    title            VARCHAR,
    tgroup           VARCHAR,
    type             VARCHAR,
    has_templ        INTEGER,
    parsed           INTEGER,
    description      VARCHAR,
    image            VARCHAR,
    on_node          INTEGER,
    on_way           INTEGER,
    on_area          INTEGER,
    on_relation      INTEGER,
    tags_implies     VARCHAR,
    tags_combination VARCHAR,
    tags_linked      VARCHAR,
    status           VARCHAR
);

DROP TABLE IF EXISTS wikipages_keys;

CREATE TABLE wikipages_keys (
    key   VARCHAR,
    langs VARCHAR
);

DROP TABLE IF EXISTS wikipages_tags;

CREATE TABLE wikipages_tags (
    key   VARCHAR,
    value VARCHAR,
    langs VARCHAR
);

DROP TABLE IF EXISTS wiki_languages;

CREATE TABLE wiki_languages (
    language    VARCHAR,
    count_pages INT
);

DROP TABLE IF EXISTS stats;

CREATE TABLE stats (
    key   VARCHAR,
    value INT64
);

