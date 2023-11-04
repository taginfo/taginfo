# web/lib/api/v4/wiki.rb
class Taginfo < Sinatra::Base

    api(4, 'wiki/languages', {
        :description => 'List languages taginfo knows about and how many wiki pages describing keys and tags there are in these languages.',
        :paging => :no,
        :result => no_paging_results([
            [:code                   , :STRING, 'Language code.'],
            [:dir                    , :STRING, 'Direction this language is written in ("ltr", "rtl", or "auto").'],
            [:native_name            , :STRING, 'Name of language in this language.'],
            [:english_name           , :STRING, 'Name of language in English.'],
            [:wiki_key_pages         , :INT,    'Number of "Key" wiki pages in this language.'],
            [:wiki_key_pages_fraction, :FLOAT,  'Number of "Key" wiki pages in this language in relation to the number of keys described in any language in the wiki.'],
            [:wiki_tag_pages         , :INT,    'Number of "Tag" wiki pages in this language.'],
            [:wiki_tag_pages_fraction, :FLOAT,  'Number of "Tag" wiki pages in this language in relation to the number of tags described in any language in the wiki.']
        ]),
        :sort => %w[ code native_name english_name wiki_key_pages wiki_tag_pages ],
        :example => { :sortname => 'wiki_key_pages', :sortorder => 'desc' },
        :ui => '/reports/languages'
    }) do
        res = @db.select('SELECT * FROM languages').
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.code
                o.native_name
                o.english_name
                o.wiki_key_pages
                o.wiki_tag_pages
            end.
            execute

        return generate_json_result(res.size,
            res.map do |row| {
                :code                    => row['code'],
                :dir                     => direction_from_lang_code(row['code']),
                :native_name             => row['native_name'],
                :english_name            => row['english_name'],
                :wiki_key_pages          => row['wiki_key_pages'].to_i,
                :wiki_key_pages_fraction => row['wiki_key_pages'].to_f / @db.stats('wiki_keys_described'),
                :wiki_tag_pages          => row['wiki_tag_pages'].to_i,
                :wiki_tag_pages_fraction => row['wiki_tag_pages'].to_f / @db.stats('wiki_tags_described')
            }
            end
        )
    end

    api(4, 'wiki/key_status', {
        :description => 'List all keys documented on the wiki with their status.',
        :parameters => {
            :status => 'Only show keys with this status (optional).'
        },
        :paging => :optional,
        :result => paging_results([
            [:status, :STRING, 'Status.'],
            [:key,    :STRING, 'Key.'],
            [:langs,  :ARRAY_OF_STRINGS, 'List of languages that have this status and key'],
        ]),
        :example => { :status => 'obsolete' },
        :ui => '/sources/wiki/tag_status#keys'
    }) do
        status = params[:status]

        if status == 'none'
            none = true
            status = ''
            total = @db.select('SELECT count(distinct key) FROM wikipages WHERE approval_status IS NULL AND value IS NULL').
                get_first_i
        else
            total = @db.select("SELECT count(distinct (coalesce(approval_status, '@') || key)) FROM wikipages").
                condition('value IS NULL').
                condition_if('approval_status = ?', status).
                get_first_i
        end

        res = @db.select("SELECT approval_status, key, json_group_array(lang) AS languages FROM wikipages").
            condition('value IS NULL').
            condition_if('approval_status = ?', status).
            condition_if_true('approval_status IS NULL', none).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.key
            end.
            group_by('approval_status, key').
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                :status => row['approval_status'],
                :key    => row['key'],
                :langs  => JSON.parse(row['languages']).sort
            }
            end
        )
    end

    api(4, 'wiki/tag_status', {
        :description => 'List all tags documented on the wiki with their status.',
        :parameters => {
            :status => 'Only show tags with this status (optional).'
        },
        :paging => :optional,
        :result => paging_results([
            [:status, :STRING, 'Status.'],
            [:key,    :STRING, 'Key.'],
            [:value,  :STRING, 'Value.'],
            [:langs,  :ARRAY_OF_STRINGS, 'List of languages that have this status, key, and value.'],
        ]),
        :example => { :status => 'obsolete' },
        :ui => '/sources/wiki/tag_status#tags'
    }) do
        status = params[:status]

        if status == 'none'
            none = true
            status = ''
            total = @db.select('SELECT count(distinct (key || value)) FROM wikipages WHERE approval_status IS NULL AND value IS NOT NULL').
                get_first_i
        else
            total = @db.select("SELECT count(distinct (coalesce(approval_status, '@') || key || value)) FROM wikipages").
                condition('value IS NOT NULL').
                condition_if('approval_status = ?', status).
                get_first_i
        end

        res = @db.select("SELECT distinct approval_status, key, value, json_group_array(lang) AS languages FROM wikipages").
            condition('value IS NOT NULL').
            condition_if('approval_status = ?', status).
            condition_if_true('approval_status IS NULL', none).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.key
                o.value
            end.
            group_by('approval_status, key, value').
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                :status => row['approval_status'],
                :key    => row['key'],
                :value  => row['value'],
                :langs  => JSON.parse(row['languages']).sort
            }
            end
        )
    end

    api(4, 'wiki/inconsistent_key_status', {
        :description => 'List all keys documented on the wiki which have a different status in different languages.',
        :paging => :optional,
        :result => paging_results([
            [:key,    :STRING, 'Key.'],
            [:counts, :HASH, 'Hash mapping status values to counts of wiki pages.'],
        ]),
        :example => {},
        :ui => '/sources/wiki/tag_status#inconsistent_keys'
    }) do
        total = @db.stats('wiki_inconsistent_status_keys')

        res = @db.select(<<EOF
WITH key_status_count AS (
    SELECT p.key, p.approval_status AS status, count(*) AS count
        FROM wikipages p, inconsistent_status_keys d
        WHERE d.key = p.key AND p.value IS NULL AND p.approval_status IS NOT NULL
        GROUP BY p.key, p.approval_status
),
res AS (
    SELECT key, json_group_object(status, count) AS counts
        FROM key_status_count GROUP BY key
)
SELECT * FROM res
EOF
            ).
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                :key    => row['key'],
                :counts => JSON.parse(row['counts']),
            }
            end
        )
    end

    api(4, 'wiki/inconsistent_tag_status', {
        :description => 'List all tags documented on the wiki which have a different status in different languages.',
        :paging => :optional,
        :result => paging_results([
            [:key,    :STRING, 'Key.'],
            [:value,  :STRING, 'Value.'],
            [:counts, :HASH, 'Hash mapping status values to counts of wiki pages.'],
        ]),
        :example => {},
        :ui => '/sources/wiki/tag_status#inconsistent_tags'
    }) do
        total = @db.stats('wiki_inconsistent_status_tags')

        res = @db.select(<<EOF
WITH tag_status_count AS (
    SELECT p.key, p.value, p.approval_status AS status, count(*) AS count
        FROM wikipages p, inconsistent_status_tags d
        WHERE d.key = p.key AND d.value = p.value AND p.approval_status IS NOT NULL
        GROUP BY p.key, p.value, p.approval_status
),
res AS (
    SELECT key, value, json_group_object(status, count) AS counts
        FROM tag_status_count GROUP BY key, value
)
SELECT * FROM res
EOF
            ).
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                :key    => row['key'],
                :value  => row['value'],
                :counts => JSON.parse(row['counts']),
            }
            end
        )
    end

    api(4, 'wiki/problems', {
        :description => 'Show problems encountered by taginfo while parsing wiki pages',
        :paging => :optional,
        :sort => %w[ title location reason lang tag ],
        :result => paging_results([
            [:title,    :STRING, 'Wiki page title where the problem occurred'],
            [:location, :STRING, 'Problem location'],
            [:reason,   :STRING, 'Problem reason'],
            [:lang,     :STRING, 'Wiki language of this page'],
            [:key,      :STRING, 'Key this wiki page is for (or null if neither "Key" nor "Tag" page)'],
            [:value,    :STRING, 'Value this wiki page is for (or null if not a "Tag" page)'],
            [:info,     :STRING, 'Informational string dependant on type of problem']
        ]),
        :example => {},
        :ui => '/sources/wiki/parsing_problems#list'
    }) do
        total = @db.count('wiki.problems').
            condition_if("location || ' ' || reason || ' ' || title || ' ' LIKE ? ESCAPE '@'", like_contains(params[:query])).
            get_first_i

        res = @db.select('SELECT * FROM wiki.problems').
            condition_if("location || ' ' || reason || ' ' || title || ' ' LIKE ? ESCAPE '@'", like_contains(params[:query])).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.location :location
                o.location :reason
                o.location :key
                o.location :value
                o.reason :reason
                o.reason :location
                o.reason :key
                o.reason :value
                o.title
                o.tag :key
                o.tag :value
                o.lang :lang
                o.lang :key
                o.lang :value
            end.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                :title    => row['title'],
                :location => row['location'],
                :reason   => row['reason'],
                :lang     => row['lang'],
                :key      => row['key'],
                :value    => row['value'],
                :info     => row['info']
            }
            end
        )
    end

end
