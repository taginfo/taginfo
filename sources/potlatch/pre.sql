--
--  Taginfo source: Potlatch
--
--  pre.sql
--

.bail ON

INSERT INTO source (id, name, update_start, data_until) SELECT 'potlatch', 'Potlatch', datetime('now'), datetime('now');

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
    name            TEXT,
    category_id     TEXT REFERENCES categories (id),
    category_name   TEXT,
    help            TEXT,
    on_point        INTEGER,
    on_line         INTEGER,
    on_area         INTEGER,
    on_relation     INTEGER,
    icon_image      TEXT,
    icon_foreground TEXT,
    icon_background TEXT
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

