--
--  Taginfo source: Wiki
--
--  post.sql
--

.bail ON

UPDATE wikipages SET status='r' WHERE type='redirect';
UPDATE wikipages SET status='p' WHERE type='page' AND has_templ='false';
UPDATE wikipages SET status='t' WHERE type='page' AND has_templ='true' AND parsed=1;
UPDATE wikipages SET status='e' WHERE type='page' AND has_templ='true' AND parsed=0;

CREATE INDEX wikipages_key_value_idx ON wikipages(key, value);

INSERT INTO wikipages_keys (key, langs) SELECT key, group_concat(lang || ' ' || status) FROM wikipages WHERE value IS NULL GROUP BY key;
INSERT INTO wikipages_tags (key, value, langs) SELECT key, value, group_concat(lang || ' ' || status) FROM wikipages WHERE value IS NOT NULL GROUP BY key, value;

INSERT INTO wiki_languages (language, count_pages) SELECT lang, count(*) FROM wikipages GROUP BY lang;

INSERT INTO stats (key, value) SELECT 'wikipages_keys',      count(*) FROM wikipages_keys;
INSERT INTO stats (key, value) SELECT 'wikipages_tags',      count(*) FROM wikipages_tags;
INSERT INTO stats (key, value) SELECT 'wikipages_languages', count(*) FROM wiki_languages;

ANALYZE;

UPDATE meta SET update_end=datetime('now');

