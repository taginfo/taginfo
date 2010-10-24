--
--  Taginfo source: Potlatch
--
--  post.sql
--

.bail ON

-- pull over category name from categories table so we don't need joins later
UPDATE features SET category_name = (SELECT name FROM categories WHERE id=category_id);

ANALYZE;

