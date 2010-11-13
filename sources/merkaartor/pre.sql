--
--  Taginfo source: Merkaartor
--
--  pre.sql
--

.bail ON

INSERT INTO source (id, name, update_start, data_until) SELECT 'merkaartor', 'Merkaartor', datetime('now'), datetime('now');

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

