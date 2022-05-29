--
--  Taginfo source: Software
--
--  post.sql
--

INSERT INTO deprecated_tags_id (key, value)
    SELECT DISTINCT key, nullif(value, '*') FROM deprecated_tags_id_mapping, json_each(deprecated_tags_id_mapping.old_tags);

INSERT INTO stats (key, value)
    SELECT 'deprecated_tags_id', count(*) FROM deprecated_tags_id;

INSERT INTO stats (key, value)
    SELECT 'discardable_tags_' || source, count(*) FROM discardable_tags GROUP BY source;

INSERT INTO stats (key, value)
    SELECT 'discardable_tags', count(distinct key) FROM discardable_tags;

ANALYZE;

UPDATE source SET update_end = datetime('now');

