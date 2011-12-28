--
--  Taginfo source: JOSM
--
--  pre.sql
--

.bail ON

INSERT INTO source (id, name, update_start, data_until) SELECT 'josm', 'JOSM', datetime('now'), datetime('now');

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
    line_color     VARCHAR,
    line_width     INTEGER,
    line_realwidth INTEGER,
    area_color     VARCHAR,
    rule           VARCHAR
);

--
--  josm_style_images
--
--  Images/Icons used in JOSM style rules
--

DROP TABLE IF EXISTS josm_style_images;

CREATE TABLE josm_style_images (
    style          VARCHAR,
    path           VARCHAR,
    png            BLOB
);

