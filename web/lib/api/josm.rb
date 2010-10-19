class Taginfo < Sinatra::Base

    get '/api/1/josm/styles' do
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
                :scale_min => row['scale_min'].nil? ? nil : row['scale_min'].to_i,
                :scale_max => row['scale_max'].nil? ? nil : row['scale_max'].to_i,
                :rule => h(row['rule'])
            } }
        }.to_json
    end

    def sort_by_for_keys
        return case params[:sortname]
            when 'k'
                ['k', 'v', 'b']
            when 'v'
                ['v', 'b', 'k']
            else
                params[:sortname]
        end
    end

    get '/api/1/josm/styles/:style' do
        total = @db.count('josm_style_rules').
            condition_if("k LIKE '%' || ? || '%' OR v LIKE '%' || ? || '%'", params[:query], params[:query]).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
            condition_if("k LIKE '%' || ? || '%' OR v LIKE '%' || ? || '%'", params[:query], params[:query]).
            order_by([:k, :v, :b, :scale_min, :scale_max], sort_by_for_keys, params[:sortorder]).
            paging(params[:rp], params[:page]).
            execute()

        return get_josm_result(total, res);
    end

    def sort_by_for_values
        return case params[:sortname]
            when 'v'
                ['v', 'b']
            when 'scale_min'
                ['scale_min', 'scale_max', 'v', 'b']
            when 'scale_max'
                ['scale_max', 'scale_min', 'v', 'b']
            else
                params[:sortname]
        end
    end

    get %r{^/api/1/josm/styles/([^/]+)/keys/(.*)} do
        style = params[:captures].first # XXX do something with this
        key   = params[:captures][1]
        
        total = @db.count('josm_style_rules').
            condition('k = ?', key).
            condition_if("v LIKE '%' || ? || '%'", params[:query]).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
            condition('k = ?', key).
            condition_if("v LIKE '%' || ? || '%'", params[:query]).
            order_by([:v, :b, :scale_min, :scale_max], sort_by_for_values, params[:sortorder]).
            paging(params[:rp], params[:page]).
            execute()

        return get_josm_result(total, res);
    end

    get '/api/1/josm/styles/:style/tags/' do
        key   = params[:key]
        value = params[:value]

        total = @db.count('josm_style_rules').
            condition('k = ?', key).
            condition('v = ?', value).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
            condition('k = ?', key).
            condition('v = ?', value).
            order_by([:scale_min], 'scale_min', 'ASC').
            paging(params[:rp], params[:page]).
            execute()

        return get_josm_result(total, res);
    end

end
