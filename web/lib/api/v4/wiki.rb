# web/lib/api/v4/wiki.rb
class Taginfo < Sinatra::Base

    api(4, 'wiki/languages', {
        :description => 'List languages taginfo knows about and how many wiki pages describing keys and tags there are in these languages.',
        :paging => :no,
        :result => {
            :code                    => :STRING,
            :native_name             => :STRING,
            :english_name            => :STRING,
            :wiki_key_pages          => :INT,
            :wiki_key_pages_fraction => :FLOAT,
            :wiki_tag_pages          => :INT,
            :wiki_tag_pages_fraction => :FLOAT
        },
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
