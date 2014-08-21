--
--  Taginfo source: Projects
--
--  post.sql
--

.bail ON

CREATE INDEX project_keys_idx ON project_tags (key) WHERE value IS NULL;
CREATE INDEX project_tags_idx ON project_tags (key, value) WHERE value IS NOT NULL;

ANALYZE;

UPDATE source SET update_end=datetime('now');

