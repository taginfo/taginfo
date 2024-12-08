--
--  Taginfo source: Wiki
--
--  post.sql
--

UPDATE wikipages SET status='r' WHERE type='redirect';
UPDATE wikipages SET status='p' WHERE type='page' AND has_templ=0;
UPDATE wikipages SET status='t' WHERE type='page' AND has_templ=1 AND parsed=1;
UPDATE wikipages SET status='e' WHERE type='page' AND has_templ=1 AND parsed=0;

CREATE INDEX wikipages_key_value_idx ON wikipages(key, value);

UPDATE relation_pages SET status='r' WHERE type='redirect';
UPDATE relation_pages SET status='p' WHERE type='page' AND has_templ=0;
UPDATE relation_pages SET status='t' WHERE type='page' AND has_templ=1 AND parsed=1;
UPDATE relation_pages SET status='e' WHERE type='page' AND has_templ=1 AND parsed=0;

CREATE TABLE inconsistent_status_keys AS
    SELECT DISTINCT a.key FROM wikipages a, wikipages b
        WHERE a.key = b.key AND a.value IS NULL AND b.value IS NULL AND a.approval_status != b.approval_status;

CREATE TABLE inconsistent_status_tags AS
    SELECT DISTINCT a.key, a.value FROM wikipages a, wikipages b
        WHERE a.key = b.key AND a.value = b.value AND a.approval_status != b.approval_status;

CREATE INDEX relation_pages_rtype_idx ON relation_pages(rtype);

CREATE INDEX wiki_images_image_idx ON wiki_images(image);

INSERT INTO wikipages_keys (key,        langs, lang_count) SELECT key,        group_concat(lang || ' ' || status), count(*) FROM wikipages WHERE value IS     NULL GROUP BY key;
INSERT INTO wikipages_tags (key, value, langs, lang_count) SELECT key, value, group_concat(lang || ' ' || status), count(*) FROM wikipages WHERE value IS NOT NULL AND value != '*' GROUP BY key, value;

INSERT INTO wiki_languages (language, count_pages) SELECT lang, count(*) FROM wikipages GROUP BY lang;

INSERT INTO stats (key, value) SELECT 'wiki_images', count(*) FROM wiki_images;

INSERT INTO stats (key, value) SELECT 'wiki_keys_described',                  count(*) FROM wikipages_keys;
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_keys',                  count(*) FROM wikipages WHERE value IS     NULL;
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_keys_redirect',         count(*) FROM wikipages WHERE value IS     NULL AND status='r';
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_keys_without_template', count(*) FROM wikipages WHERE value IS     NULL AND status='p';
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_keys_with_template',    count(*) FROM wikipages WHERE value IS     NULL AND status='t';
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_keys_with_error',       count(*) FROM wikipages WHERE value IS     NULL AND status='e';

INSERT INTO stats (key, value) SELECT 'wiki_tags_described',                  count(*) FROM wikipages_tags;
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_tags',                  count(*) FROM wikipages WHERE value IS NOT NULL;
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_tags_redirect',         count(*) FROM wikipages WHERE value IS NOT NULL AND status='r';
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_tags_without_template', count(*) FROM wikipages WHERE value IS NOT NULL AND status='p';
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_tags_with_template',    count(*) FROM wikipages WHERE value IS NOT NULL AND status='t';
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_tags_with_error',       count(*) FROM wikipages WHERE value IS NOT NULL AND status='e';

INSERT INTO stats (key, value) SELECT 'wiki_pages_for_relation_types',                  count(*) FROM relation_pages;
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_relation_types_redirect',         count(*) FROM relation_pages WHERE status='r';
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_relation_types_without_template', count(*) FROM relation_pages WHERE status='p';
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_relation_types_with_template',    count(*) FROM relation_pages WHERE status='t';
INSERT INTO stats (key, value) SELECT 'wiki_pages_for_relation_types_with_error',       count(*) FROM relation_pages WHERE status='e';

INSERT INTO stats (key, value) SELECT 'wiki_languages', count(*) FROM wiki_languages;

INSERT INTO stats (key, value) SELECT 'wiki_inconsistent_status_keys', count(*) FROM inconsistent_status_keys;
INSERT INTO stats (key, value) SELECT 'wiki_inconsistent_status_tags', count(*) FROM inconsistent_status_tags;

ANALYZE;

UPDATE source SET update_end=datetime('now');

