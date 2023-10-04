--
--  Taginfo source: Projects
--
--  post.sql
--

INSERT INTO stats (key, value) SELECT 'projects', count(*) FROM projects;
INSERT INTO stats (key, value) SELECT 'projects_ok', count(*) FROM projects WHERE status='OK';
INSERT INTO stats (key, value) SELECT 'projects_fetch_error', count(*) FROM projects WHERE status='FETCH ERROR';
INSERT INTO stats (key, value) SELECT 'projects_parse_error', count(*) FROM projects WHERE status='PARSE ERROR';
INSERT INTO stats (key, value) SELECT 'projects_with_icon', count(*) FROM projects WHERE icon IS NOT NULL;
INSERT INTO stats (key, value) SELECT 'project_keys', count(*) FROM project_tags WHERE value IS NULL;
INSERT INTO stats (key, value) SELECT 'project_tags', count(*) FROM project_tags WHERE value IS NOT NULL;

-- ============================================================================

UPDATE projects SET key_entries=(SELECT count(*) FROM project_tags WHERE project_id=id AND value IS NULL);
UPDATE projects SET tag_entries=(SELECT count(*) FROM project_tags WHERE project_id=id AND value IS NOT NULL);

UPDATE projects SET unique_keys=(SELECT count(DISTINCT key)                 FROM project_tags WHERE project_id=id);
UPDATE projects SET unique_tags=(SELECT count(DISTINCT key || '=' || value) FROM project_tags WHERE project_id=id AND value IS NOT NULL);

CREATE INDEX project_tags_key_value_idx ON project_tags (key, value);

ANALYZE;

UPDATE source SET update_end=datetime('now');

