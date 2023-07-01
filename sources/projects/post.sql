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

CREATE TABLE project_unique_keys (
    key       VARCHAR NOT NULL,
    projects  INTEGER,
    in_wiki   INTEGER,
    count_all INTEGER
);

INSERT INTO project_unique_keys (key, projects)
    SELECT key, count(*) FROM (SELECT DISTINCT key, project_id FROM project_tags) GROUP BY key;

INSERT INTO stats (key, value) SELECT 'project_unique_keys', count(*) FROM project_unique_keys;

CREATE TABLE project_unique_tags (
    key       VARCHAR NOT NULL,
    value     VARCHAR NOT NULL,
    projects  INTEGER,
    in_wiki   INTEGER,
    count_all INTEGER
);

INSERT INTO project_unique_tags (key, value, projects)
    SELECT key, value, count(*) FROM (SELECT DISTINCT key, value, project_id FROM project_tags WHERE value IS NOT NULL) GROUP BY key, value;

INSERT INTO stats (key, value) SELECT 'project_unique_tags', count(*) FROM project_unique_tags;

CREATE INDEX project_unique_keys_key_idx ON project_unique_keys(key);

CREATE INDEX project_unique_tags_key_value_idx ON project_unique_tags(key, value);

-- ============================================================================

UPDATE projects SET key_entries=(SELECT count(*) FROM project_tags WHERE project_id=id AND value IS NULL);
UPDATE projects SET tag_entries=(SELECT count(*) FROM project_tags WHERE project_id=id AND value IS NOT NULL);

UPDATE projects SET unique_keys=(SELECT count(DISTINCT key)                 FROM project_tags WHERE project_id=id);
UPDATE projects SET unique_tags=(SELECT count(DISTINCT key || '=' || value) FROM project_tags WHERE project_id=id AND value IS NOT NULL);

ANALYZE;

UPDATE source SET update_end=datetime('now');

