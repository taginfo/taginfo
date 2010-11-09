--
--  Taginfo source: JOSM
--
--  post.sql
--

.bail ON

CREATE INDEX josm_style_rules_idx ON josm_style_rules (style, k, v);

INSERT INTO stats (key, value) SELECT 'josm_styles', count(*) FROM josm_styles;

INSERT INTO stats (key, value) SELECT 'josm_style_rules_for_keys', count(*) FROM josm_style_rules WHERE v IS     NULL;
INSERT INTO stats (key, value) SELECT 'josm_style_rules_for_tags', count(*) FROM josm_style_rules WHERE v IS NOT NULL;

INSERT INTO stats (key, value) SELECT 'josm_keys_in_style_rules', count(distinct k)             FROM josm_style_rules WHERE v IS     NULL;
INSERT INTO stats (key, value) SELECT 'josm_tags_in_style_rules', count(distinct k || '=' || v) FROM josm_style_rules WHERE v IS NOT NULL;

ANALYZE;

UPDATE meta SET update_end=datetime('now');

