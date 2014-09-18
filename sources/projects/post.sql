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

CREATE TABLE project_counts (
    key   TEXT NOT NULL,
    value TEXT,
    num   INTEGER
);

INSERT INTO project_counts (key, value, num) SELECT key, NULL, count(*) FROM (SELECT DISTINCT project_id, key FROM project_tags) GROUP BY key;
INSERT INTO project_counts (key, value, num) SELECT key, value, count(*) FROM (SELECT DISTINCT project_id, key, value FROM project_tags WHERE value IS NOT NULL) GROUP BY key, value;

ANALYZE;

UPDATE source SET update_end=datetime('now');

