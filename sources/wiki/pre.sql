--
--  Taginfo source: Wiki
--
--  pre.sql
--

INSERT INTO source (id, name, update_start, data_until) SELECT 'wiki', 'Wiki', datetime('now'), datetime('now');

DROP TABLE IF EXISTS wikipages;

CREATE TABLE wikipages (
    lang               TEXT,
    tag                TEXT,
    key                TEXT,
    value              TEXT,
    title              TEXT,
    body               TEXT,
    tgroup             TEXT,
    type               TEXT,
    has_templ          INTEGER,
    parsed             INTEGER,
    redirect_target    TEXT,
    description        TEXT,
    image              TEXT,
    osmcarto_rendering TEXT,
    on_node            INTEGER,
    on_way             INTEGER,
    on_area            INTEGER,
    on_relation        INTEGER,
    tags_implies       TEXT,
    tags_combination   TEXT,
    tags_linked        TEXT,
    status             TEXT,
    statuslink         TEXT,
    wikidata           TEXT
);

DROP TABLE IF EXISTS relation_pages;

CREATE TABLE relation_pages (
    lang               TEXT,
    rtype              TEXT,
    title              TEXT,
    body               TEXT,
    tgroup             TEXT,
    type               TEXT,
    has_templ          INTEGER,
    parsed             INTEGER,
    redirect_target    TEXT,
    description        TEXT,
    image              TEXT,
    osmcarto_rendering TEXT,
    tags_linked        TEXT,
    status             TEXT
);

DROP TABLE IF EXISTS wiki_images;

CREATE TABLE wiki_images (
    image            TEXT,
    width            INTEGER,
    height           INTEGER,
    size             INTEGER,
    mime             TEXT,
    image_url        TEXT,
    thumb_url_prefix TEXT,
    thumb_url_suffix TEXT
);

DROP TABLE IF EXISTS wikipages_keys;

CREATE TABLE wikipages_keys (
    key        TEXT,
    langs      TEXT,
    lang_count INTEGER
);

DROP TABLE IF EXISTS wikipages_tags;

CREATE TABLE wikipages_tags (
    key        TEXT,
    value      TEXT,
    langs      TEXT,
    lang_count INTEGER
);

DROP TABLE IF EXISTS wiki_languages;

CREATE TABLE wiki_languages (
    language    TEXT,
    count_pages INTEGER
);

DROP TABLE IF EXISTS wiki_links;

CREATE TABLE wiki_links (
    link_class TEXT,
    from_title TEXT,
    from_lang  TEXT,
    from_type  TEXT,
    from_name  TEXT,
    to_title   TEXT,
    to_lang    TEXT,
    to_type    TEXT,
    to_name    TEXT
);

DROP TABLE IF EXISTS tag_page_related_terms;

CREATE TABLE tag_page_related_terms (
    key   TEXT,
    value TEXT,
    lang  TEXT,
    term  TEXT
);

DROP TABLE IF EXISTS relation_page_related_terms;

CREATE TABLE relation_page_related_terms (
    rtype TEXT,
    lang  TEXT,
    term  TEXT
);

DROP TABLE IF EXISTS tag_page_wikipedia_links;

CREATE TABLE tag_page_wikipedia_links (
    key   TEXT,
    value TEXT,
    lang  TEXT,
    title TEXT
);

DROP TABLE IF EXISTS relation_page_wikipedia_links;

CREATE TABLE relation_page_wikipedia_links (
    rtype TEXT,
    lang  TEXT,
    title TEXT
);

DROP TABLE IF EXISTS problems;

CREATE TABLE problems (
    location TEXT,
    reason   TEXT,
    title    TEXT,
    lang     TEXT,
    key      TEXT,
    value    TEXT,
    info     TEXT
);

DROP TABLE IF EXISTS words;

CREATE TABLE words (
    key   TEXT,
    value TEXT,
    words TEXT
);

