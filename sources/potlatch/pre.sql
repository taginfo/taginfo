--
--  Taginfo source: Potlatch
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
--  categories
--

DROP TABLE IF EXISTS categories;

CREATE TABLE categories (
    id   TEXT,
    name TEXT
);


--
--  features
--

DROP TABLE IF EXISTS features;

CREATE TABLE features (
    name          TEXT,
    category_id   TEXT REFERENCES categories (id),
    category_name TEXT,
    help          TEXT,
    on_point      INTEGER,
    on_line       INTEGER,
    on_area       INTEGER,
    on_relation   INTEGER
);

--
--  tags
--

DROP TABLE IF EXISTS tags;

CREATE TABLE tags (
    key          TEXT,
    value        TEXT,
    feature_name REFERENCES features (name)
);

