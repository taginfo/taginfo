# web/lib/api/v4/search.rb
class Taginfo < Sinatra::Base

    api(4, 'search/by_key_and_value', {
        :description => 'Search for tags by key and/or value.',
        :parameters => { :query => 'Value to search for (substring search, required).' },
        :sort => %w( count_all key value ),
        :paging => :optional,
        :result => paging_results([
            [:key,       :STRING, 'Key'],
            [:value,     :STRING, 'Value'],
            [:count_all, :INT,    'Number of objects in the database with this tag.']
        ]),
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
            total = @db.execute('SELECT count(*) FROM (SELECT rowid FROM search.ftsearch WHERE value MATCH ? INTERSECT SELECT rowid FROM search.ftsearch WHERE key MATCH ?)', query_value, query_key)[0][0].to_i
            sel = @db.select('SELECT * FROM search.ftsearch WHERE value MATCH ? INTERSECT SELECT * FROM search.ftsearch WHERE key MATCH ?', query_value, query_key)
        end

        res = sel.
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.count_all
                o.key
                o.value
            }.
            paging(@ap).
            execute()

        return generate_json_result(total,
            res.map{ |row| {
                :key       => row['key'],
                :value     => row['value'],
                :count_all => row['count_all'].to_i,
            }}
        )
    end

    api(4, 'search/by_keyword', {
        :description => 'Search for keys and tags by keyword in wiki pages.',
        :parameters => { :query => 'Value to search for (substring search, required).' },
        :sort => %w( count_all key value ),
        :paging => :optional,
        :result => paging_results([
            [:key,   :STRING, 'Key'],
            [:value, :STRING, 'Value']
        ]),
        :example => { :query => 'fire', :page => 1, :rp => 10 },
        :ui => '/search?q=fire#fulltext'
    }) do
        query = params[:query].downcase

        total = @db.count('wiki.words').condition("words LIKE ? ESCAPE '@'", like_contains(query)).get_first_i

        res = @db.select("SELECT key, value FROM wiki.words WHERE words LIKE ? ESCAPE '@'", like_contains(query)).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.key
                o.value
            }.
            paging(@ap).
            execute()

        return generate_json_result(total,
            res.map{ |row| {
                :key   => row['key'],
                :value => row['value']
            }}
        )
    end

    api(4, 'search/by_role', {
        :description => 'Search for relation roles.',
        :parameters => { :query => 'Role to search for (substring search, required).' },
        :sort => %w( count_all rtype role ),
        :paging => :optional,
        :result => paging_results([
            [:rtype,     :STRING, 'Relation type.'],
            [:role,      :STRING, 'Role'],
            [:count_all, :INT,    'Number of objects in the database with this role.']
        ]),
        :example => { :query => 'foo', :page => 1, :rp => 10 },
        :ui => '/search?q=foo#roles'
    }) do
        query = params[:query]

        total = @db.count('db.relation_roles').
            condition_if("role LIKE ? ESCAPE '@'", like_contains(query)).
            get_first_value().to_i

        res = @db.select('SELECT rtype, role, count_all FROM db.relation_roles').
            condition_if("role LIKE ? ESCAPE '@'", like_contains(query)).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.count_all
                o.rtype
                o.role
            }.
            paging(@ap).
            execute()

        return generate_json_result(total,
            res.map{ |row| {
                :rtype     => row['rtype'],
                :role      => row['role'],
                :count_all => row['count_all'].to_i,
            }}
        )
    end

    api(4, 'search/by_value', {
        :description => 'Search for tags by value.',
        :parameters => { :query => 'Value to search for (substring search, required).' },
        :sort => %w( count_all key value ),
        :paging => :optional,
        :result => paging_results([
            [:key,       :STRING, 'Key'],
            [:value,     :STRING, 'Value'],
            [:count_all, :INT,    'Number of objects in the database with this tag.']
        ]),
        :example => { :query => 'foo', :page => 1, :rp => 10 },
        :ui => '/search?q=foo#values'
    }) do
        query = params[:query]

        # searching for the empty string is very expensive, so we'll just return an empty result
        if query == ''
            return generate_json_result(0, []);
        end

        total = @db.count('search.ftsearch').
            condition("value MATCH ?", query).
            get_first_value().to_i

        res = @db.select('SELECT * FROM search.ftsearch').
            condition("value MATCH ?", query).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.count_all
                o.key
                o.value
            }.
            paging(@ap).
            execute()

        return generate_json_result(total,
            res.map{ |row| {
                :key       => row['key'],
                :value     => row['value'],
                :count_all => row['count_all'].to_i,
            }}
        )
    end

end
