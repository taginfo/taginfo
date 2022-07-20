
CREATE INDEX keys_chronology_key ON keys_chronology (key);

CREATE INDEX tags_chronology_key_value ON tags_chronology (key, value);

INSERT INTO stats (key, value)
    SELECT 'chronology_num_keys', count(*) FROM keys_chronology;

ANALYZE;

UPDATE source SET update_end=datetime('now');

