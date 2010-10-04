--
--  Taginfo source: JOSM
--
--  post.sql
--

.bail ON

CREATE INDEX josm_style_rules_idx ON josm_style_rules (style, k, v);

ANALYZE;

UPDATE meta SET update_end=datetime('now');

