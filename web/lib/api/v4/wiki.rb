# web/lib/api/v4/wiki.rb
class Taginfo < Sinatra::Base

    api(4, 'wiki/languages', {
        :description => 'List languages taginfo knows about and how many wiki pages describing keys and tags there are in these languages.',
        :paging => :no,
        :result => no_paging_results([
            [:code                   , :STRING, 'Language code.'],
            [:native_name            , :STRING, 'Name of language in this language.'],
            [:english_name           , :STRING, 'Name of language in English.'],
            [:wiki_key_pages         , :INT,    'Number of "Key" wiki pages in this language.'],
            [:wiki_key_pages_fraction, :FLOAT,  'Number of "Key" wiki pages in this language in relation to the number of keys described in any language in the wiki.'],
            [:wiki_tag_pages         , :INT,    'Number of "Tag" wiki pages in this language.'],
            [:wiki_tag_pages_fraction, :FLOAT,  'Number of "Tag" wiki pages in this language in relation to the number of tags described in any language in the wiki.']
        ]),
        :sort => %w( code native_name english_name wiki_key_pages wiki_tag_pages ),
        :example => { :sortname => 'wiki_key_pages', :sortorder => 'desc' },
        :ui => '/reports/languages'
    }) do
        res = @db.select('SELECT * FROM languages').
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.code
                o.native_name
                o.english_name
                o.wiki_key_pages
                o.wiki_tag_pages
            }.
            execute()

        return {
            :total => res.size,
            :data  => res.map{ |row| {
                :code                    => row['code'],
                :native_name             => row['native_name'],
                :english_name            => row['english_name'],
                :wiki_key_pages          => row['wiki_key_pages'].to_i,
                :wiki_key_pages_fraction => row['wiki_key_pages'].to_f / @db.stats('wiki_keys_described'),
                :wiki_tag_pages          => row['wiki_tag_pages'].to_i,
                :wiki_tag_pages_fraction => row['wiki_tag_pages'].to_f / @db.stats('wiki_tags_described'),
            } }
        }.to_json
    end

end
