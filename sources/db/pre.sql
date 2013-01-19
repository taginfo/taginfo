--
--  Taginfo source: Database
--
--  pre.sql
--

.bail ON

INSERT INTO source (id, name, update_start) SELECT 'db', 'Database', datetime('now');

DROP TABLE IF EXISTS keys;

CREATE TABLE keys (
  key              VARCHAR,
  count_all        INTEGER DEFAULT 0,
  count_nodes      INTEGER DEFAULT 0,
  count_ways       INTEGER DEFAULT 0,
  count_relations  INTEGER DEFAULT 0,
  values_all       INTEGER DEFAULT 0,
  values_nodes     INTEGER DEFAULT 0,
  values_ways      INTEGER DEFAULT 0,
  values_relations INTEGER DEFAULT 0,
  users_all        INTEGER DEFAULT 0,
  users_nodes      INTEGER DEFAULT 0,
  users_ways       INTEGER DEFAULT 0,
  users_relations  INTEGER DEFAULT 0,
  cells_nodes      INTEGER DEFAULT 0,
  cells_ways       INTEGER DEFAULT 0,
  in_wiki          INTEGER DEFAULT 0,
  in_wiki_en       INTEGER DEFAULT 0,
  in_josm          INTEGER DEFAULT 0,
  in_potlatch      INTEGER DEFAULT 0,
  in_merkaartor    INTEGER DEFAULT 0,
  characters       VARCHAR
);

DROP TABLE IF EXISTS prevalent_values;

CREATE TABLE prevalent_values (
  key      TEXT,
  value    TEXT,
  count    INTEGER,
  fraction REAL
);


DROP TABLE IF EXISTS key_distributions;

CREATE TABLE key_distributions (
  key              VARCHAR,
  object_type      VARCHAR(1),          -- (n)ode, (w)ay,
  png              BLOB
);

DROP TABLE IF EXISTS tags;

CREATE TABLE tags (
  key              VARCHAR,
  value            VARCHAR,
  count_all        INTEGER DEFAULT 0,
  count_nodes      INTEGER DEFAULT 0,
  count_ways       INTEGER DEFAULT 0,
  count_relations  INTEGER DEFAULT 0,
  object_type      VARCHAR(1),          -- (n)ode, (w)ay, (r)elation
  object_id        INTEGER,
  in_wiki          INTEGER DEFAULT 0,
  in_wiki_en       INTEGER DEFAULT 0,
  in_josm          INTEGER DEFAULT 0,
  in_potlatch      INTEGER DEFAULT 0,
  in_merkaartor    INTEGER DEFAULT 0
);

DROP TABLE IF EXISTS key_combinations;

CREATE TABLE key_combinations (
  key1             VARCHAR,
  key2             VARCHAR,
  count_all        INTEGER,
  count_nodes      INTEGER,
  count_ways       INTEGER,
  count_relations  INTEGER 
);

DROP TABLE IF EXISTS tag_combinations;

CREATE TABLE tag_combinations (
  key1             VARCHAR,
  value1           VARCHAR,
  key2             VARCHAR,
  value2           VARCHAR,
  count_all        INTEGER,
  count_nodes      INTEGER,
  count_ways       INTEGER,
  count_relations  INTEGER 
);

DROP TABLE IF EXISTS relation_types;

CREATE TABLE relation_types (
  rtype             VARCHAR,
  count             INTEGER,
  members_all       INTEGER,
  members_nodes     INTEGER,
  members_ways      INTEGER,
  members_relations INTEGER
);

DROP TABLE IF EXISTS relation_roles;

CREATE TABLE relation_roles (
  rtype            VARCHAR,
  role             VARCHAR,
  count_all        INTEGER,
  count_nodes      INTEGER,
  count_ways       INTEGER,
  count_relations  INTEGER
);

DROP TABLE IF EXISTS prevalent_roles;

CREATE TABLE prevalent_roles (
  rtype    TEXT,
  role     TEXT,
  count    INTEGER,
  fraction REAL
);

DROP TABLE IF EXISTS selected_tags;

CREATE TABLE selected_tags (
  skey             VARCHAR,
  svalue           VARCHAR,
  count_all        INTEGER DEFAULT 0,
  count_nodes      INTEGER DEFAULT 0,
  count_ways       INTEGER DEFAULT 0,
  count_relations  INTEGER DEFAULT 0
);

