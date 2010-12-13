# web/lib/api/josm.rb
class Taginfo < Sinatra::Base

    get '/api/2/josm/styles' do
        # XXX dummy function
        return [
            { :id => 'standard', :name => 'standard', :url => '' }
        ].to_json
    end

    def get_josm_result(total, res)
        return {
            :page  => params[:page].to_i,
            :rp    => params[:rp].to_i,
            :total => total,
            :data  => res.map{ |row| {
                :k => row['k'],
                :v => row['v'],
                :b => row['b'],
                :rule => h(row['rule'])
            } }
        }.to_json
    end

    get '/api/2/josm/styles/:style' do
        total = @db.count('josm_style_rules').
            condition_if("k LIKE '%' || ? || '%' OR v LIKE '%' || ? || '%'", params[:query], params[:query]).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
            condition_if("k LIKE '%' || ? || '%' OR v LIKE '%' || ? || '%'", params[:query], params[:query]).
            order_by(params[:sortname], params[:sortorder]){ |o|
                o.k :k
                o.k :v
                o.k :b
                o.v :v
                o.v :b
                o.v :k
                o.b
            }.
            paging(params[:rp], params[:page]).
            execute()

        return get_josm_result(total, res);
    end

    get '/api/2/josm/styles/:style/keys' do
        style = params[:style] # XXX do something with this
        key   = params[:key]
        
        total = @db.count('josm_style_rules').
            condition('k = ?', key).
            condition_if("v LIKE '%' || ? || '%'", params[:query]).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
            condition('k = ?', key).
            condition_if("v LIKE '%' || ? || '%'", params[:query]).
            order_by(params[:sortname], params[:sortorder]){ |o|
                o.v :v
                o.v :b
                o.b
            }.
            paging(params[:rp], params[:page]).
            execute()

        return get_josm_result(total, res);
    end

    get '/api/2/josm/styles/:style/tags' do
        key   = params[:key]
        value = params[:value]

        total = @db.count('josm_style_rules').
            condition('k = ?', key).
            condition('v = ?', value).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
            condition('k = ?', key).
            condition('v = ?', value).
            order_by([:k, :v]).
            paging(params[:rp], params[:page]).
            execute()

        return get_josm_result(total, res);
    end

end
