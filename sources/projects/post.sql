--
--  Taginfo source: Projects
--
--  post.sql
--

.bail ON

INSERT INTO stats (key, value) SELECT 'projects', count(*) FROM projects;
INSERT INTO stats (key, value) SELECT 'projects_ok', count(*) FROM projects WHERE status='OK';
INSERT INTO stats (key, value) SELECT 'project_keys', count(*) FROM project_tags WHERE value IS NULL;
INSERT INTO stats (key, value) SELECT 'project_tags', count(*) FROM project_tags WHERE value IS NOT NULL;

ANALYZE;

UPDATE source SET update_end=datetime('now');

