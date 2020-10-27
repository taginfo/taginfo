
ANALYZE keys_chronology;

CREATE INDEX keys_chronology_key ON keys_chronology (key);

ANALYZE tags_chronology;

CREATE INDEX tags_chronology_key_value ON tags_chronology (key, value);

