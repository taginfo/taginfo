--
--  Taginfo
--
--  languages.sql
--

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
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('az',      'az', 'Azerbaijani', 'Azərbaycan dili');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('bg',      'bg', 'Bulgarian', 'Български език');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('bn',      'bn', 'Bengali', 'বাংলা');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ca',      'ca', 'Catalan', 'Català');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('cs',      'cs', 'Czech', 'Čeština');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('cz',      'cz', 'Czech', 'Česky');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('da',      'da', 'Danish', 'Dansk');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('de',      'de', 'German', 'Deutsch');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('el',      'el', 'Greek', 'Ελληνικά');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('en',      'en', 'English', 'English');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('eo',      'eo', 'Esperanto', 'Esperanto');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('es',      'es', 'Spanish', 'Español');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('et',      'et', 'Estonian', 'Eesti');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('fa',      'fa', 'Farsi', 'فارسی');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('fi',      'fi', 'Finish', 'Suomi');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('fr',      'fr', 'French', 'Français');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('gl',      'gl', 'Galician', 'Galego');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('he',      'he', 'Hebrew', 'עברית');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('hr',      'hr', 'Croatian', 'Hrvatski');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ht',      'ht', 'Haitian Creole', 'Kreyòl ayisyen');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('hu',      'hu', 'Hungarian', 'Magyar');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('id',      'id', 'Indonesian', 'Bahasa Indonesia');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('it',      'it', 'Italian', 'Italiano');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ja',      'ja', 'Japanese', '日本語');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ko',      'ko', 'Korean', '한국어');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('lt',      'lt', 'Lithuanian', 'Lietuvių Kalba');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('lv',      'lv', 'Latvian', 'Latviešu Valoda');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ms',      'ms', 'Malay', 'Bahasa Melayu');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ne',      'ne', 'Nepali', 'नेपाली');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('nl',      'nl', 'Dutch', 'Nederlands');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('no',      'no', 'Norwegian', 'Norsk');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('oc',      'oc', 'Occitan', 'occitan');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('pl',      'pl', 'Polish', 'Polski');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('pt',      'pt', 'Portuguese', 'Português');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('pt-br',   NULL, 'Brazilian Portuguese', 'Português do Brasil');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ro',      'ro', 'Romanian', 'Română');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ro-md',   NULL, 'Moldovan', 'Română (Moldova)');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('ru',      'ru', 'Russian', 'Русский');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('sh',      'sh', 'Serbo-Croatian', 'Serbo-Croatian');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('sk',      'sk', 'Slovak', 'Slovenský');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('sq',      'sq', 'Albanian', 'Shqip');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('sr',      'sr', 'Serbian', 'српски језик / srpski jezik');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('sv',      'sv', 'Swedish', 'Svenska');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('tr',      'tr', 'Turkish', 'Türkçe');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('uk',      'uk', 'Ukrainian', 'Українська');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('vi',      'vi', 'Vietnamese', 'Tiếng Việt');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('zh-hans', NULL, 'Simplified Chinese', '简体中文');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('zh-hant', NULL, 'Traditional Chinese', '繁體中文');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('zh-cn',   NULL, 'Simplified Chinese', '简体中文');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('zh-tw',   NULL, 'Traditional Chinese', '繁體中文');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('gcf',     NULL, 'Guadeloupean Creole French', 'Gwadloupéyen');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('pnb',     NULL, 'Western Panjabi', 'پَن٘جابی');
INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('yue',     'zh', 'Yue Chinese/Cantonese', '粤语');
-- INSERT INTO languages (code, iso639_1, english_name, native_name) VALUES ('', '', '', '');

ANALYZE languages;

