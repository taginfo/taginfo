-- ============================================================================
--
--  Taginfo
--
--  interesting_tags.sql
--
-- ============================================================================

.bail ON

ATTACH DATABASE '__DIR__/db/taginfo-db.db'                 AS db;
ATTACH DATABASE '__DIR__/wiki/taginfo-wiki.db'             AS wiki;
ATTACH DATABASE '__DIR__/josm/taginfo-josm.db'             AS josm; 
ATTACH DATABASE '__DIR__/potlatch/taginfo-potlatch.db'     AS potlatch; 

-- ============================================================================

DROP TABLE IF EXISTS interesting_tags;
CREATE TABLE interesting_tags (
    key   TEXT,
    value TEXT
);

INSERT INTO interesting_tags (key, value)
    SELECT DISTINCT key, NULL FROM db.keys WHERE count_all > 10000
    UNION
    SELECT key, value FROM db.tags WHERE count_all > 10000;

DELETE FROM interesting_tags WHERE key IN ('created_by', 'ele', 'height', 'is_in', 'lanes', 'layer', 'maxspeed', 'name', 'ref', 'width') AND value IS NOT NULL;
DELETE FROM interesting_tags WHERE value IS NOT NULL AND key LIKE '%:%';
DELETE FROM interesting_tags WHERE value IS NOT NULL AND key LIKE 'fresno_%';

ANALYZE interesting_tags;

.output __DIR__/db/interesting_tags.lst

SELECT key FROM interesting_tags WHERE value IS NULL ORDER BY key;
SELECT key || '=' || value FROM interesting_tags WHERE value IS NOT NULL ORDER BY key, value;

-- ============================================================================
