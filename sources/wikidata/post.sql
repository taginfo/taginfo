--
--  Taginfo source: Wikidata
--
--  post.sql
--

INSERT INTO stats (key, value) SELECT 'wikidata_p1282', count(*) FROM wikidata_p1282;
INSERT INTO stats (key, value) SELECT 'wikidata_p1282_errors', count(*) FROM wikidata_p1282_errors;

INSERT INTO stats (key, value) SELECT 'wikidata_p1282_' || ptype, count(*) FROM wikidata_p1282 GROUP BY ptype;
INSERT INTO stats (key, value) SELECT 'wikidata_p1282_pcode', count(*) FROM wikidata_p1282 WHERE code LIKE 'P%';
INSERT INTO stats (key, value) SELECT 'wikidata_p1282_qcode', count(*) FROM wikidata_p1282 WHERE code LIKE 'Q%';

-- ============================================================================

CREATE INDEX wikidata_p1282_key_value_idx ON wikidata_p1282 (key, value) WHERE key IS NOT NULL;
CREATE INDEX wikidata_p1282_relation_type_idx ON wikidata_p1282 (relation_type) WHERE relation_type IS NOT NULL;

CREATE INDEX wikidata_labels_code_lang_idx ON wikidata_labels (code, lang);

-- ============================================================================

ANALYZE;

UPDATE source SET update_end=datetime('now');

