--
--  Taginfo
--  
--  languages.sql
--

.bail ON

DROP TABLE IF EXISTS languages;

CREATE TABLE languages (
    code         VARCHAR,
    english_name VARCHAR,
    native_name  VARCHAR
);

INSERT INTO languages VALUES ('ar', 'Arabic', 'العربية');
INSERT INTO languages VALUES ('bg', 'Bulgarian', 'български език');
INSERT INTO languages VALUES ('cz', 'Czech', 'česky');
INSERT INTO languages VALUES ('da', 'Danish', 'dansk');
INSERT INTO languages VALUES ('de', 'German', 'Deutsch');
INSERT INTO languages VALUES ('en', 'English', 'English');
INSERT INTO languages VALUES ('es', 'Spanish', 'español');
INSERT INTO languages VALUES ('et', 'Estonian', 'eesti');
INSERT INTO languages VALUES ('fi', 'Finish', 'suomi');
INSERT INTO languages VALUES ('fr', 'French', 'français');
INSERT INTO languages VALUES ('he', 'Hebrew', 'עברית');
INSERT INTO languages VALUES ('hr', 'Croatian', 'hrvatski');
INSERT INTO languages VALUES ('hu', 'Hungarian', 'Magyar');
INSERT INTO languages VALUES ('it', 'Italian', 'Italiano');
INSERT INTO languages VALUES ('ja', 'Japanese', '日本語');
INSERT INTO languages VALUES ('nl', 'Dutch', 'Nederlands');
INSERT INTO languages VALUES ('no', 'Norwegian', 'Norsk');
INSERT INTO languages VALUES ('pl', 'Polish', 'polski');
INSERT INTO languages VALUES ('pt', 'Portuguese', 'Português');
INSERT INTO languages VALUES ('pt-br', 'Brazilian Portuguese', 'Português do Brasil');
INSERT INTO languages VALUES ('ro', 'Romanian', 'română');
INSERT INTO languages VALUES ('ro-md', 'Moldovan', 'română (Moldova)');
INSERT INTO languages VALUES ('ru', 'Russian', 'русский язык');
-- INSERT INTO languages VALUES ('sh', '', ''); -- not in ISO 639-1
INSERT INTO languages VALUES ('sq', 'Albanian', 'Shqip');
INSERT INTO languages VALUES ('sv', 'Swedish', 'svenska');
INSERT INTO languages VALUES ('tr', 'Turkish', 'Türkçe');
INSERT INTO languages VALUES ('uk', 'Ukrainian', 'українська');
INSERT INTO languages VALUES ('zh', 'Chinese', '中文');
INSERT INTO languages VALUES ('zh-hans', 'Chinese', '中文'); -- hans?
-- INSERT INTO languages VALUES ('', '', '');

ANALYZE;

