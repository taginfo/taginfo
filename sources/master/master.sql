-- ============================================================================
--
--  Taginfo
--
--  master.sql
--
-- ============================================================================

.bail ON

ATTACH DATABASE '__DIR__/db/taginfo-db.db'               AS db;
ATTACH DATABASE '__DIR__/wiki/taginfo-wiki.db'           AS wiki;
ATTACH DATABASE '__DIR__/languages/taginfo-languages.db' AS languages;
ATTACH DATABASE '__DIR__/projects/taginfo-projects.db'   AS projects;

-- ============================================================================

--
--  Collects information about all the sources.
--
DROP TABLE IF EXISTS sources;
CREATE TABLE sources (
    no           INTEGER,
    visible      INTEGER,
    id           TEXT,
    name         TEXT,
    update_start TEXT,
    update_end   TEXT,
    data_until   TEXT
);

INSERT INTO sources SELECT 1, 1, * FROM db.source
              UNION SELECT 2, 1, * FROM wiki.source
              UNION SELECT 3, 1, * FROM languages.source
              UNION SELECT 4, 1, * FROM projects.source;

DROP TABLE IF EXISTS master_stats;
CREATE TABLE master_stats (
    key   TEXT,
    value INT64
);

INSERT INTO master_stats SELECT * FROM db.stats
                   UNION SELECT * FROM wiki.stats
                   UNION SELECT * FROM projects.stats;

-- ============================================================================

INSERT INTO db.keys (key) SELECT DISTINCT key FROM wiki.wikipages WHERE key NOT IN (SELECT key FROM db.keys);

UPDATE db.keys SET in_wiki=1    WHERE key IN (SELECT distinct key FROM wiki.wikipages WHERE value IS NULL);
UPDATE db.keys SET in_wiki_en=1 WHERE key IN (SELECT distinct key FROM wiki.wikipages WHERE value IS NULL AND lang='en');

-- ============================================================================

-- too slow, so we drop it for now
-- INSERT INTO db.tags (key, value) SELECT DISTINCT key, value FROM wiki.wikipages WHERE key || '=XX=' || value NOT IN (SELECT key || '=XX=' || value FROM db.tags);

UPDATE db.tags SET in_wiki=1    WHERE key IN (SELECT distinct key FROM wiki.wikipages WHERE value IS NOT NULL AND value != '*') AND key || '=' || value IN (SELECT distinct tag FROM wiki.wikipages WHERE value IS NOT NULL AND value != '*');
UPDATE db.tags SET in_wiki_en=1 WHERE key IN (SELECT distinct key FROM wiki.wikipages WHERE value IS NOT NULL AND value != '*' AND lang='en') AND key || '=' || value IN (SELECT distinct tag FROM wiki.wikipages WHERE value IS NOT NULL AND value != '*' AND lang='en');

-- ============================================================================

DROP TABLE IF EXISTS top_tags;
CREATE TABLE top_tags (
  skey            VARCHAR,
  svalue          VARCHAR,
  count_all       INTEGER DEFAULT 0,
  count_nodes     INTEGER DEFAULT 0,
  count_ways      INTEGER DEFAULT 0,
  count_relations INTEGER DEFAULT 0,
  in_wiki         INTEGER DEFAULT 0,
  in_wiki_en      INTEGER DEFAULT 0,
  in_projects     INTEGER DEFAULT 0
);

INSERT INTO top_tags (skey, svalue)
    SELECT key1, value1 FROM db.tag_combinations WHERE value1 != ''
    UNION
    SELECT key2, value2 FROM db.tag_combinations WHERE value2 != '';

UPDATE top_tags SET
    count_all       = (SELECT t.count_all       FROM db.tags t WHERE t.key=skey AND t.value=svalue),
    count_nodes     = (SELECT t.count_nodes     FROM db.tags t WHERE t.key=skey AND t.value=svalue),
    count_ways      = (SELECT t.count_ways      FROM db.tags t WHERE t.key=skey AND t.value=svalue),
    count_relations = (SELECT t.count_relations FROM db.tags t WHERE t.key=skey AND t.value=svalue);

UPDATE top_tags SET in_wiki=1    WHERE skey || '=' || svalue IN (SELECT distinct tag FROM wiki.wikipages WHERE value IS NOT NULL AND value != '*');
UPDATE top_tags SET in_wiki_en=1 WHERE skey || '=' || svalue IN (SELECT distinct tag FROM wiki.wikipages WHERE value IS NOT NULL AND value != '*' AND lang='en');

UPDATE top_tags SET in_projects=(SELECT num FROM projects.project_counts p WHERE p.key=skey AND p.value=svalue);

CREATE UNIQUE INDEX top_tags_key_value_idx ON top_tags (skey, svalue);

-- ============================================================================

DROP TABLE IF EXISTS popular_keys;
CREATE TABLE popular_keys (
    key           VARCHAR,
    count         INTEGER,
    users         INTEGER,
    wikipages     INTEGER DEFAULT 0,
    in_wiki       INTEGER DEFAULT 0,
    in_wiki_en    INTEGER DEFAULT 0,
    scale_count   REAL,
    scale_users   REAL,
    scale_wiki    REAL,
    scale_name    REAL,
    scale1        REAL,
    scale2        REAL
);

INSERT INTO popular_keys (key, count, users)
    SELECT key, count_all, users_all FROM db.keys WHERE count_all > 1000 GROUP BY key;

-- count number of wikipages for each key
UPDATE popular_keys SET wikipages = (SELECT count(*) FROM wiki.wikipages w WHERE w.key=popular_keys.key);

UPDATE popular_keys SET in_wiki=1    WHERE key IN (SELECT distinct key FROM wiki.wikipages);
UPDATE popular_keys SET in_wiki_en=1 WHERE key IN (SELECT distinct key FROM wiki.wikipages WHERE lang='en');

-- ============================================================================

DROP TABLE IF EXISTS popular_metadata;
CREATE TABLE popular_metadata (
    keys        INTEGER,
    count_min   INTEGER,
    count_max   INTEGER,
    count_delta INTEGER,
    users_min   INTEGER,
    users_max   INTEGER,
    users_delta INTEGER
);

INSERT INTO popular_metadata (keys, count_min, count_max, count_delta, users_min, users_max, users_delta)
    SELECT count(*), min(count), max(count), max(count) - min(count), min(users), max(users), max(users) - min(users) FROM popular_keys;

UPDATE popular_keys SET scale_count = CAST (count - (SELECT count_min FROM popular_metadata) AS REAL) / (SELECT count_delta FROM popular_metadata);
UPDATE popular_keys SET scale_users = CAST (users - (SELECT users_min FROM popular_metadata) AS REAL) / (SELECT users_delta FROM popular_metadata);
UPDATE popular_keys SET scale_wiki  = CAST (wikipages AS REAL) / (SELECT max(wikipages) FROM popular_keys);
UPDATE popular_keys SET scale_name  = 1;
UPDATE popular_keys SET scale_name  = 0 WHERE key LIKE '%:%';

UPDATE popular_keys SET scale1 = 10 * scale_count + 8 * scale_users + 2 * scale_wiki + 2 * scale_name;

-- ============================================================================

INSERT INTO languages (code) SELECT distinct(lang) FROM wiki.wikipages WHERE lang NOT IN (SELECT code FROM languages);
UPDATE languages SET wiki_key_pages=(SELECT count(distinct key) FROM wiki.wikipages WHERE lang=code AND value IS NULL);
UPDATE languages SET wiki_tag_pages=(SELECT count(distinct key) FROM wiki.wikipages WHERE lang=code AND value IS NOT NULL);

-- ============================================================================

DROP TABLE IF EXISTS suggestions;
CREATE TABLE suggestions (
    key     TEXT,
    value   TEXT,
    count   INTEGER,
    in_wiki INTEGER DEFAULT 0,
    score   INTEGER
);

INSERT INTO suggestions (key, value, count) SELECT key, NULL, count_all FROM db.keys WHERE count_all > 10000 OR in_wiki = 1;
INSERT INTO suggestions (key, value, count) SELECT key, value, count FROM db.prevalent_values WHERE count > 1000;

INSERT INTO suggestions (key, value, in_wiki) SELECT key, value, 1 FROM wiki.wikipages WHERE value IS NOT NULL AND key || '=' || value NOT IN (SELECT key || '=' || value FROM suggestions);

DELETE FROM suggestions WHERE count < 100;

UPDATE suggestions SET score = count * (1+in_wiki);

-- ============================================================================

ANALYZE;

