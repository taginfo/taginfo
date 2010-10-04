--
--  Taginfo source: JOSM
--
--  pre.sql
--

.bail ON

DROP TABLE IF EXISTS meta;

CREATE TABLE meta (
    source_id    TEXT,
    source_name  TEXT,
    update_start TEXT,
    update_end   TEXT,
    data_until   TEXT
);

INSERT INTO meta (source_id, source_name, update_start, data_until) SELECT 'josm', 'JOSM', datetime('now'), datetime('now');

DROP TABLE IF EXISTS stats;

CREATE TABLE stats (
    key   TEXT,
    value INT64
);

--
--  josm_styles
--
--  Contains list of JOSM styles.
--

DROP TABLE IF EXISTS josm_styles;

CREATE TABLE josm_styles (
    style           VARCHAR
);

--
--  josm_style_rules
--
--  Contains data about JOSM style rules.
--

DROP TABLE IF EXISTS josm_style_rules;

CREATE TABLE josm_style_rules (
    style          VARCHAR,
    k              VARCHAR,
    v              VARCHAR,
    b              VARCHAR,
    scale_min      INTEGER,
    scale_max      INTEGER,
    icon_source    VARCHAR,
    line_width     INTEGER,
    line_realwidth INTEGER,
    rule           VARCHAR
);

