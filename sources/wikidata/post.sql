--
--  Taginfo source: Wikidata
--
--  post.sql
--

INSERT INTO stats (key, value) SELECT 'wikidata_keys', count(*) FROM wikidata_keys;
INSERT INTO stats (key, value) SELECT 'wikidata_tags', count(*) FROM wikidata_tags;

INSERT INTO stats (key, value) SELECT 'wikidata_distinct_keys', count(distinct key) FROM wikidata_keys;
INSERT INTO stats (key, value) SELECT 'wikidata_distinct_tags', count(distinct key || '=' || value) FROM wikidata_tags;

INSERT INTO stats (key, value) SELECT 'wikidata_labels', count(*) FROM wikidata_labels;
INSERT INTO stats (key, value) SELECT 'wikidata_errors', count(*) FROM wikidata_errors;

INSERT INTO stats (key, value) SELECT 'wikidata_keys_pcode', count(*) FROM wikidata_keys WHERE code LIKE 'P%';
INSERT INTO stats (key, value) SELECT 'wikidata_keys_qcode', count(*) FROM wikidata_keys WHERE code LIKE 'Q%';
INSERT INTO stats (key, value) SELECT 'wikidata_tags_pcode', count(*) FROM wikidata_tags WHERE code LIKE 'P%';
INSERT INTO stats (key, value) SELECT 'wikidata_tags_qcode', count(*) FROM wikidata_tags WHERE code LIKE 'Q%';

-- ============================================================================

CREATE INDEX wikidata_keys_key_idx ON wikidata_keys (key);
CREATE INDEX wikidata_tags_key_value_idx ON wikidata_tags (key, value);

CREATE INDEX wikidata_labels_code_lang_idx ON wikidata_labels (code, lang);

-- ============================================================================

ANALYZE;

UPDATE source SET update_end=datetime('now');

