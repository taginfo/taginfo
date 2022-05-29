--
--  Taginfo source: Wiki
--
--  cache-images.sql
--

CREATE TABLE cache_pages (
    title     TEXT,
    timestamp INT,
    body      TEXT
);

CREATE INDEX cache_pages_title_timestamp_idx ON cache_pages (title, timestamp);

