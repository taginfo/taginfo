--
--  Taginfo source: Database
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

INSERT INTO meta (source_id, source_name, update_start) SELECT 'db', 'Database', datetime('now');

DROP TABLE IF EXISTS stats;

CREATE TABLE stats (
    key   TEXT,
    value INT64
);

DROP TABLE IF EXISTS keys;

CREATE TABLE keys (
  key              VARCHAR,
  count_all        INTEGER,
  count_nodes      INTEGER,
  count_ways       INTEGER,
  count_relations  INTEGER,
  values_all       INTEGER,
  values_nodes     INTEGER,
  values_ways      INTEGER,
  values_relations INTEGER,
  users_all        INTEGER,
  users_nodes      INTEGER,
  users_ways       INTEGER,
  users_relations  INTEGER,
  grids            INTEGER,
  prevalent_values TEXT
);

DROP TABLE IF EXISTS key_distributions;

CREATE TABLE key_distributions (
  key              VARCHAR,
  png              BLOB
);

DROP TABLE IF EXISTS tags;

CREATE TABLE tags (
  key              VARCHAR,
  value            VARCHAR,
  count_all        INTEGER,
  count_nodes      INTEGER,
  count_ways       INTEGER,
  count_relations  INTEGER 
);

DROP TABLE IF EXISTS keypairs;

CREATE TABLE keypairs (
  key1             VARCHAR,
  key2             VARCHAR,
  count_all        INTEGER,
  count_nodes      INTEGER,
  count_ways       INTEGER,
  count_relations  INTEGER 
);

