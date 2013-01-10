--
--  Taginfo source: Wiki
--
--  cache.sql
--

.bail ON

CREATE TABLE cache_pages (
    title     TEXT,
    timestamp TEXT,
    body      TEXT
);

CREATE INDEX cache_pages_title_timestamp ON cache_pages (title, timestamp);

