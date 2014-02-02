--
--  Taginfo
--  
--  languages.sql
--

.bail ON

--
--  Contains all the languages Taginfo knows about.
--
DROP TABLE IF EXISTS languages;
CREATE TABLE languages (
    code           VARCHAR,
    iso639_1       VARCHAR, -- official ISO 639-1 code (if available)
    english_name   VARCHAR,
    native_name    VARCHAR,
    wiki_key_pages INTEGER, -- count of wiki pages with the title "code:Key:*" (or "Key:*" for code='en')
    wiki_tag_pages INTEGER  -- count of wiki pages with the title "code:Tag:*" (or "Tag:*" for code='en')
);

INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ar',      'ar', 'Arabic', 'العربية');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('az',      'az', 'Azerbaijani', 'azərbaycan dili');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('bg',      'bg', 'Bulgarian', 'български език');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ca',      'ca', 'Catalan', 'català');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('cs',      'cs', 'Czech', 'čeština');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('cz',      'cz', 'Czech', 'česky');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('da',      'da', 'Danish', 'dansk');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('de',      'de', 'German', 'Deutsch');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('en',      'en', 'English', 'English');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('es',      'es', 'Spanish', 'español');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('et',      'et', 'Estonian', 'eesti');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('fi',      'fi', 'Finish', 'suomi');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('fr',      'fr', 'French', 'français');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('he',      'he', 'Hebrew', 'עברית');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('hr',      'hr', 'Croatian', 'hrvatski');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ht',      'ht', 'Haitian Creole', 'Kreyòl ayisyen');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('hu',      'hu', 'Hungarian', 'Magyar');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('it',      'it', 'Italian', 'Italiano');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ja',      'ja', 'Japanese', '日本語');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ko',      'ko', 'Korean', '한국어 (韓國語)');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('lt',      'lt', 'Lithuanian', 'lietuvių kalba');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('lv',      'lv', 'Latvian', 'latviešu valoda');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('nl',      'nl', 'Dutch', 'Nederlands');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('no',      'no', 'Norwegian', 'Norsk');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('pl',      'pl', 'Polish', 'polski');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('pt',      'pt', 'Portuguese', 'Português');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('pt-br',   NULL, 'Brazilian Portuguese', 'Português do Brasil');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ro',      'ro', 'Romanian', 'română');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ro-md',   NULL, 'Moldovan', 'română (Moldova)');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ru',      'ru', 'Russian', 'русский язык');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('sk',      'sk', 'Slovak', 'slovenský jazyk');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('sq',      'sq', 'Albanian', 'Shqip');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('sv',      'sv', 'Swedish', 'svenska');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('tr',      'tr', 'Turkish', 'Türkçe');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('uk',      'uk', 'Ukrainian', 'українська');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('zh',      'zh', 'Chinese', '中文');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('zh-hans', NULL, 'Simplified Chinese', '简体字');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('zh-hant', NULL, 'Traditional Chinese', '簡體字');
-- INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('', '', '', '');

