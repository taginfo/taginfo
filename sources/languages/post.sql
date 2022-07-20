--
--  Taginfo source: Languages
--
--  post.sql
--

INSERT INTO stats (key, value)
    SELECT 'subtag_' || stype, count(*) FROM subtags GROUP BY stype;

INSERT INTO stats (key, value)
    SELECT 'wikipedia_sites', count(*) FROM wikipedia_sites;

CREATE INDEX unicode_data_codepoint_idx ON unicode_data (codepoint);

ANALYZE;

UPDATE source SET update_end=datetime('now');

