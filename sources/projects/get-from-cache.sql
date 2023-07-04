--
--  Taginfo source: Projects
--
--  get-from-cache.sql
--

ATTACH DATABASE 'file:__DIR__/projects-cache.db?mode=ro' AS cache;

INSERT INTO projects (id, json_url, last_modified, fetch_date, fetch_status, fetch_json, status, data_updated)
    SELECT id, json_url, last_modified, fetch_date, fetch_status, fetch_json, CASE WHEN fetch_status = '200' THEN 'OK' ELSE 'FETCH ERROR' END, last_modified
        FROM cache.fetch_log
        WHERE fetch_status = '200';

