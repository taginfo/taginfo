--
--  Taginfo source: Projects
--
--  post.sql
--

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

UPDATE projects SET key_entries=(SELECT count(*) FROM project_tags WHERE project_id=id AND value IS NULL);
UPDATE projects SET tag_entries=(SELECT count(*) FROM project_tags WHERE project_id=id AND value IS NOT NULL);

UPDATE projects SET unique_keys=(SELECT count(DISTINCT key)                 FROM project_tags WHERE project_id=id);
UPDATE projects SET unique_tags=(SELECT count(DISTINCT key || '=' || value) FROM project_tags WHERE project_id=id AND value IS NOT NULL);

ANALYZE;

UPDATE source SET update_end=datetime('now');

