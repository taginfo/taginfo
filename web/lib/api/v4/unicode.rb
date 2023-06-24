# web/lib/api/v4/unicode.rb
class Taginfo < Sinatra::Base

    api(4, 'unicode/characters', {
        :description => 'Get information about unicode characters.',
        :parameters => {
            :string => 'Character string (required).'
        },
        :paging => :optional,
        :result => paging_results([
            [:char,        :TEXT, 'Unicode character.'],
            [:codepoint,   :INT,  'Unicode code point.'],
            [:script,      :TEXT, 'Code (Xxxx) of script this character is in.'],
            [:script_name, :TEXT, 'Name of script this character is in.'],
            [:category,    :TEXT, 'Unicode general category (Xx) of this character.'],
            [:name,        :TEXT, 'Unicode name of this character (null if unknown).']
        ]),
        :example => { :string => 'highway' },
        :ui => '/keys/highway#characters'
    }) do
        str = params[:string]

        res = @db.select("
WITH RECURSIVE
generate_series(value) AS (
  SELECT 1
  UNION ALL
  SELECT value + 1 FROM generate_series
   WHERE value + 1 <= length(?)
),
codepoints AS (
  SELECT value AS num, unicode(substr(?, value, 1)) AS cp FROM generate_series
),
data AS (
  SELECT c.num, c.cp, d.script, d.category, d.name FROM codepoints c LEFT OUTER JOIN unicode_data d ON d.codepoint = c.cp
),
script AS (
  SELECT d.num, d.cp AS codepoint, COALESCE(d.script, m.script) AS script, COALESCE(d.category, m.category) AS category, d.name FROM data d LEFT OUTER JOIN unicode_codepoint_script_mapping m ON m.codepoint_from <= d.cp AND m.codepoint_to >= d.cp
)
SELECT codepoint, d.script, s.name AS script_name, category, d.name FROM script d, unicode_scripts s WHERE d.script = s.script ORDER BY num", str, str).
            paging(@ap).
            execute

        return generate_json_result(str.length,
            res.map do |row| {
                :char        => row['codepoint'].chr(Encoding::UTF_8),
                :codepoint   => row['codepoint'],
                :script      => row['script'],
                :script_name => row['script_name'],
                :category    => row['category'],
                :name        => row['name']
            }
            end
        )
    end

end
