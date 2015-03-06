--
--  Taginfo source: Database
--
--  post.sql
--

.bail ON

PRAGMA journal_mode  = OFF;
PRAGMA synchronous   = OFF;
PRAGMA count_changes = OFF;
PRAGMA temp_store    = MEMORY;
PRAGMA cache_size    = 5000000;

-- ============================================================================

-- For all keys found to be similar earlier, we get the counts how often they
-- appear in the OSM database and store this data in the same table for easy
-- access.
UPDATE similar_keys SET count_all1=(SELECT k.count_all FROM keys k WHERE k.key=similar_keys.key1);
UPDATE similar_keys SET count_all2=(SELECT k.count_all FROM keys k WHERE k.key=similar_keys.key2);

CREATE INDEX similar_keys_key1_idx ON similar_keys (key1);
CREATE INDEX similar_keys_key2_idx ON similar_keys (key2);

ANALYZE similar_keys;

DROP TABLE IF EXISTS similar_keys_common_rare;

CREATE TABLE similar_keys_common_rare (
  key_common       VARCHAR,
  key_rare         VARCHAR,
  count_all_common INTEGER DEFAULT 0,
  count_all_rare   INTEGER DEFAULT 0,
  similarity       INTEGER
);

INSERT INTO similar_keys_common_rare (key_common, key_rare, count_all_common, count_all_rare, similarity)
    SELECT key1, key2, count_all1, count_all2, similarity
        FROM similar_keys WHERE count_all1 >= 1000 AND count_all2 <= 10 AND count_all2 > 0;

INSERT INTO similar_keys_common_rare (key_common, key_rare, count_all_common, count_all_rare, similarity)
    SELECT key2, key1, count_all2, count_all1, similarity
        FROM similar_keys WHERE count_all2 >= 1000 AND count_all1 <= 10 AND count_all1 > 0;

-- ============================================================================

CREATE UNIQUE INDEX keys_key_idx ON keys (key);
CREATE        INDEX tags_key_idx ON tags (key);
-- CREATE UNIQUE INDEX tags_key_value_idx ON tags (key, value);
CREATE        INDEX key_combinations_key1_idx ON key_combinations (key1);
CREATE        INDEX key_combinations_key2_idx ON key_combinations (key2);
CREATE UNIQUE INDEX key_distributions_key_idx ON key_distributions (key, object_type);

CREATE UNIQUE INDEX tag_distributions_key_value_idx ON tag_distributions (key, value, object_type);

CREATE        INDEX tag_combinations_key1_value1_idx ON tag_combinations (key1, value1);
CREATE        INDEX tag_combinations_key2_value2_idx ON tag_combinations (key2, value2);

CREATE UNIQUE INDEX relation_types_rtype_idx ON relation_types (rtype);
CREATE        INDEX relation_roles_rtype_idx ON relation_roles (rtype);

-- ============================================================================

INSERT INTO stats (key, value) SELECT 'num_keys',                  count(*) FROM keys;
INSERT INTO stats (key, value) SELECT 'num_keys_on_nodes',         count(*) FROM keys WHERE count_nodes     > 0;
INSERT INTO stats (key, value) SELECT 'num_keys_on_ways',          count(*) FROM keys WHERE count_ways      > 0;
INSERT INTO stats (key, value) SELECT 'num_keys_on_relations',     count(*) FROM keys WHERE count_relations > 0;

INSERT INTO stats (key, value) SELECT 'num_similar_keys',             count(*) FROM similar_keys;
INSERT INTO stats (key, value) SELECT 'num_similar_keys_common_rare', count(*) FROM similar_keys_common_rare;

INSERT INTO stats (key, value) SELECT 'num_tags',                  count(*) FROM tags;
INSERT INTO stats (key, value) SELECT 'num_tags_on_nodes',         count(*) FROM tags WHERE count_nodes     > 0;
INSERT INTO stats (key, value) SELECT 'num_tags_on_ways',          count(*) FROM tags WHERE count_ways      > 0;
INSERT INTO stats (key, value) SELECT 'num_tags_on_relations',     count(*) FROM tags WHERE count_relations > 0;

INSERT INTO stats (key, value) SELECT 'num_key_combinations',              count(*) FROM key_combinations;
INSERT INTO stats (key, value) SELECT 'num_key_combinations_on_nodes',     count(*) FROM key_combinations WHERE count_nodes     > 0;
INSERT INTO stats (key, value) SELECT 'num_key_combinations_on_ways',      count(*) FROM key_combinations WHERE count_ways      > 0;
INSERT INTO stats (key, value) SELECT 'num_key_combinations_on_relations', count(*) FROM key_combinations WHERE count_relations > 0;

INSERT INTO stats (key, value) SELECT 'characters_in_keys_plain',   count(*) FROM keys WHERE characters='plain';
INSERT INTO stats (key, value) SELECT 'characters_in_keys_colon',   count(*) FROM keys WHERE characters='colon';
INSERT INTO stats (key, value) SELECT 'characters_in_keys_letters', count(*) FROM keys WHERE characters='letters';
INSERT INTO stats (key, value) SELECT 'characters_in_keys_space',   count(*) FROM keys WHERE characters='space';
INSERT INTO stats (key, value) SELECT 'characters_in_keys_problem', count(*) FROM keys WHERE characters='problem';
INSERT INTO stats (key, value) SELECT 'characters_in_keys_rest',    count(*) FROM keys WHERE characters='rest';

INSERT INTO stats (key, value) VALUES ('objects',     (SELECT sum(value) FROM stats WHERE key IN ('nodes', 'ways', 'relations')));
INSERT INTO stats (key, value) VALUES ('object_tags', (SELECT sum(value) FROM stats WHERE key IN ('node_tags', 'way_tags', 'relation_tags')));

INSERT INTO prevalent_values (key, value, count, fraction)
            SELECT t.key, t.value, t.count_all, CAST(t.count_all AS REAL) / CAST(k.count_all AS REAL) FROM tags t, keys k
                    WHERE t.key       = k.key
                      AND t.count_all > k.count_all / 100.0;

CREATE INDEX prevalent_values_key_idx ON prevalent_values (key);

INSERT INTO stats (key, value) SELECT 'relation_types_with_detail', count(*) FROM relation_types;

INSERT INTO relation_types (rtype, count) SELECT value, count_relations FROM tags WHERE key='type' AND count_relations > 0 AND value NOT IN (SELECT rtype FROM relation_types);

INSERT INTO stats (key, value) SELECT 'relation_types', count(*) FROM relation_types;
INSERT INTO stats (key, value) SELECT 'relation_roles', count(*) FROM relation_roles;

INSERT INTO prevalent_roles (rtype, role, count, fraction)
            SELECT t.rtype, r.role, r.count_all, round(CAST(r.count_all AS REAL) / CAST(t.members_all AS REAL), 4) FROM relation_types t, relation_roles r
                    WHERE t.rtype = r.rtype
                      AND r.count_all > t.members_all / 100.0;

CREATE INDEX prevalent_roles_rtype_idx ON prevalent_roles (rtype);


ANALYZE;

UPDATE source SET update_end=datetime('now');

