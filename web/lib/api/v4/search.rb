# web/lib/api/v4/search.rb
class Taginfo < Sinatra::Base

    api(4, 'search/by_value', {
        :description => 'Search for tags by value.',
        :parameters => { :query => 'Value to search for (substring search, required).' },
        :sort => %w( count_all key value ),
        :paging => :optional,
        :result => {
            :key       => :STRING,
            :value     => :STRING,
            :count_all => :INT
        },
        :example => { :query => 'foo', :page => 1, :rp => 10 },
        :ui => '/search?q=foo#values'
    }) do
        query = params[:query]

        total = @db.count('search.ftsearch').
            condition_if("value MATCH ?", query).
            get_first_value().to_i

        res = @db.select('SELECT * FROM search.ftsearch').
            condition_if("value MATCH ?", query).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.count_all
                o.key
                o.value
            }.
            paging(@ap).
            execute()

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map{ |row| {
                :key       => row['key'],
                :value     => row['value'],
                :count_all => row['count_all'].to_i,
            }}
        }.to_json
    end

    api(4, 'search/by_key_and_value', {
        :description => 'Search for tags by key and/or value.',
        :parameters => { :query => 'Value to search for (substring search, required).' },
        :sort => %w( count_all key value ),
        :paging => :optional,
        :result => {
            :key       => :STRING,
            :value     => :STRING,
            :count_all => :INT
        },
        :example => { :query => 'highway%3Dresidential', :page => 1, :rp => 10 },
        :ui => '/search?q=highway%3Dresidential'
    }) do
        query = params[:query]
        (query_key, query_value) = query.split('=', 2)

        if query_key == ''
            total = @db.execute('SELECT count(*) FROM search.ftsearch WHERE value MATCH ?', query_value)[0][0].to_i
            sel = @db.select('SELECT * FROM search.ftsearch WHERE value MATCH ?', query_value)
        elsif query_value == ''
            total = @db.execute('SELECT count(*) FROM search.ftsearch WHERE key MATCH ?', query_key)[0][0].to_i
            sel = @db.select('SELECT * FROM search.ftsearch WHERE key MATCH ?', query_key)
        else
            total = @db.execute('SELECT count(*) FROM (SELECT * FROM search.ftsearch WHERE key MATCH ? INTERSECT SELECT * FROM search.ftsearch WHERE value MATCH ?)', query_key, query_value)[0][0].to_i
            sel = @db.select('SELECT * FROM search.ftsearch WHERE key MATCH ? INTERSECT SELECT * FROM search.ftsearch WHERE value MATCH ?', query_key, query_value)
        end

        res = sel.
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.count_all
                o.key
                o.value
            }.
            paging(@ap).
            execute()

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map{ |row| {
                :key       => row['key'],
                :value     => row['value'],
                :count_all => row['count_all'].to_i,
            }}
        }.to_json
    end

    api(4, 'search/by_keyword', {
        :description => 'Search for keys and tags by keyword in wiki pages.',
        :parameters => { :query => 'Value to search for (substring search, required).' },
        :sort => %w( count_all key value ),
        :paging => :optional,
        :result => {
            :key       => :STRING,
            :value     => :STRING
        },
        :example => { :query => 'fire', :page => 1, :rp => 10 },
        :ui => '/search?q=fire#fulltext'
    }) do
        query = params[:query].downcase

        total = @db.count('wiki.words').condition("words LIKE ('%' || ? || '%')", query).get_first_value().to_i
        sel = @db.select("SELECT key, value FROM wiki.words WHERE words LIKE ('%' || ? || '%')", query)

        res = sel.
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.key
                o.value
            }.
            paging(@ap).
            execute()

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map{ |row| {
                :key   => row['key'],
                :value => row['value']
            }}
        }.to_json
    end

end
