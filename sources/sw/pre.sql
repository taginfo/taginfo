--
--  Taginfo source: Software
--
--  pre.sql
--

INSERT INTO source (id, name, update_start, data_until) SELECT 'sw', 'Software', datetime('now'), datetime('now');

DROP TABLE IF EXISTS deprecated_tags_id_mapping;

-- From Id editor: A list of old tags mapped to new tags
CREATE TABLE deprecated_tags_id_mapping (
    old_tags     jsonb,
    replace_tags jsonb
);

DROP TABLE IF EXISTS deprecated_tags_id;

CREATE TABLE deprecated_tags_id (
    key   text NOT NULL,
    value text
);

DROP TABLE IF EXISTS discardable_tags;

-- Tags that can be removed when editing features
CREATE TABLE discardable_tags (
    source text NOT NULL,
    key    text NOT NULL
);

