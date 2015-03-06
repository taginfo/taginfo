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

