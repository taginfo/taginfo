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

    api(0, 'wiki/problems', {
        :description => 'Show problems encountered by taginfo while parsing wiki pages',
        :paging => :optional,
        :sort => %w[ location reason title lang tag ],
        :result => paging_results([
            [:location, :STRING, 'Problem location'],
            [:reason,   :STRING, 'Problem reason'],
            [:title,    :STRING, 'Wiki page title where the problem occurred'],
            [:lang,     :STRING, 'Wiki language of this page'],
            [:key,      :STRING, 'Key this wiki page is for (or null if neither "Key" nor "Tag" page)'],
            [:value,    :STRING, 'Value this wiki page is for (or null if not a "Tag" page)'],
            [:info,     :STRING, 'Informational string dependant on type of problem']
        ]),
        :example => {},
        :ui => '/taginfo/wiki-problems#list'
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
                :location => row['location'],
                :reason   => row['reason'],
                :title    => row['title'],
                :lang     => row['lang'],
                :key      => row['key'],
                :value    => row['value'],
                :info     => row['info']
            }
            end
        )
    end

end
