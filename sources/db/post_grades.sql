--
--  Taginfo source: Database
--
--  post_grades.sql
--

.bail ON

PRAGMA journal_mode  = OFF;
PRAGMA synchronous   = OFF;
PRAGMA temp_store    = MEMORY;
PRAGMA cache_size    = 5000000;

-- ============================================================================

-- BAD KEYS:

-- All keys containing whitespace or other problematic characters.
UPDATE keys SET grade='b' WHERE characters IN ('space', 'problem');

-- All keys documented in the wiki but never used.
UPDATE keys SET grade='b' WHERE characters IS NULL;

-- All other keys not used at least 10 times with strange characters in them.
UPDATE keys SET grade='b' WHERE count_all < 10 AND characters='rest';

-- All keys with less than three characters are bad
UPDATE keys SET grade='b' WHERE length(key) < 3;

-- ============================================================================

-- GOOD KEYS:

-- Documented in the wiki or used more than 100 times if they use letters,
-- underscores and colons only.
UPDATE keys SET grade='g' WHERE ((in_wiki=1 AND count_all > 0) OR (count_all > 100)) AND characters IN ('plain', 'colon', 'letters');

-- Languages can contain '-' characters, so we have a few extra "good" keys.
UPDATE keys SET grade='g' WHERE key LIKE '%name:%-%';

-- Everything used more than 1000 times is good. Of course thats not the case,
-- but we avoid overwhelming users with stuff they think they need to fix.
UPDATE keys SET grade='g' WHERE count_all > 1000;

-- ============================================================================

-- SELECT grade, count(*), sum(count_all) FROM keys GROUP BY grade;


