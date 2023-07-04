--
--  Taginfo source: Projects
--
--  cache.sql
--

CREATE TABLE fetch_log (
    id            TEXT NOT NULL,
    json_url      TEXT NOT NULL,
    last_modified DATE,
    fetch_date    DATE,
    fetch_status  TEXT, -- HTTP status code
    fetch_json    TEXT  -- HTTP body
);

