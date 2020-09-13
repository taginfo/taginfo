--
--  Taginfo source: Projects
--
--  pre.sql
--

INSERT INTO source (id, name, update_start, data_until) SELECT 'projects', 'Projects', datetime('now'), datetime('now');

DROP TABLE IF EXISTS projects;

CREATE TABLE projects (
    id            TEXT NOT NULL PRIMARY KEY,
    json_url      TEXT NOT NULL,
    last_modified DATE,
    fetch_date    DATE,
    fetch_status  TEXT, -- HTTP status code
    fetch_json    TEXT, -- HTTP body
    status        TEXT, -- 'OK', 'FETCH ERROR', 'PARSE ERROR'
    error_log     TEXT,
    data_format   INTEGER,
    data_updated  DATE,
    data_url      TEXT,
    name          TEXT,
    description   TEXT,
    project_url   TEXT,
    doc_url       TEXT,
    icon_url      TEXT,
    contact_name  TEXT,
    contact_email TEXT,
    keywords      TEXT,
    icon          BLOB,
    key_entries   INTEGER DEFAULT 0,
    tag_entries   INTEGER DEFAULT 0,
    unique_keys   INTEGER DEFAULT 0,
    unique_tags   INTEGER DEFAULT 0
);

DROP TABLE IF EXISTS project_tags;

CREATE TABLE project_tags (
    project_id  TEXT NOT NULL,
    key         TEXT NOT NULL,
    value       TEXT,
    on_node     INTEGER,
    on_way      INTEGER,
    on_relation INTEGER,
    on_area     INTEGER,
    description TEXT,
    doc_url     TEXT,
    icon_url    TEXT,
    keywords    TEXT,
    in_wiki     INTEGER DEFAULT 0,
    count_all   INTEGER DEFAULT 0
);

