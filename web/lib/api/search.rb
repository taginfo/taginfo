# web/lib/api/search.rb
class Taginfo < Sinatra::Base

    get '/api/2/search/keys' do
        query = params[:q]
    end

    get '/api/2/search/values' do
        query = params[:q]

        total = @db.count('search.ftsearch').
            condition_if("value MATCH ?", query).
            get_first_value().to_i

        res = @db.select('SELECT * FROM search.ftsearch').
            condition_if("value MATCH ?", query).
            order_by(params[:sortname], params[:sortorder]) { |o|
                o.count_all
                o.key
                o.value
            }.
            paging(params[:rp], params[:page]).
            execute()

        return {
            :page  => params[:page].to_i,
            :rp    => params[:rp].to_i,
            :total => total,
            :data  => res.map{ |row| {
                :key       => row['key'],
                :value     => row['value'],
                :count_all => row['count_all'].to_i,
            }}
        }.to_json
    end

    get '/api/2/search/tags' do
        query = params[:q]
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
            order_by(params[:sortname], params[:sortorder]) { |o|
                o.count_all
                o.key
                o.value
            }.
            paging(params[:rp], params[:page]).
            execute()

        return {
            :page  => params[:page].to_i,
            :rp    => params[:rp].to_i,
            :total => total,
            :data  => res.map{ |row| {
                :key       => row['key'],
                :value     => row['value'],
                :count_all => row['count_all'].to_i,
            }}
        }.to_json
    end

    get '/api/2/search/wiki' do
        query = params[:q]
    end

end
