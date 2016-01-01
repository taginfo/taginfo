--
--  Taginfo source: Database
--
--  post_similar_keys.sql
--

-- need this index now...
CREATE UNIQUE INDEX keys_key_idx ON keys (key);

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

