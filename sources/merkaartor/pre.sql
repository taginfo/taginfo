--
--  Taginfo source: Merkaartor
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

INSERT INTO meta (source_id, source_name, update_start, data_until) SELECT 'potlatch', 'Potlatch', datetime('now'), datetime('now');

DROP TABLE IF EXISTS stats;

CREATE TABLE stats (
    key   TEXT,
    value INT64
);


--
--  templates
--

DROP TABLE IF EXISTS templates;

CREATE TABLE templates (
    name TEXT
);

--
--  keys
--

DROP TABLE IF EXISTS keys;

CREATE TABLE keys (
    template TEXT,
    key      TEXT,
    tag_type TEXT,
    link     TEXT,
    selector TEXT
);

--
--  key_descriptions
--

DROP TABLE IF EXISTS key_descriptions;

CREATE TABLE key_descriptions (
    template    TEXT,
    key         TEXT,
    lang        TEXT,
    description TEXT
);

--
--  tags
--

DROP TABLE IF EXISTS tags;

CREATE TABLE tags (
    template TEXT,
    key      TEXT,
    value    TEXT,
    link     TEXT
);

--
--  tag_descriptions
--

DROP TABLE IF EXISTS tag_descriptions;

CREATE TABLE tag_descriptions (
    template    TEXT,
    key         TEXT,
    value       TEXT,
    lang        TEXT,
    description TEXT
);

