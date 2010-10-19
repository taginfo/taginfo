# api/db.rb
class Taginfo < Sinatra::Base

    get '/api/2/db/keys' do
        total = @db.count('db.keys').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            get_first_value().to_i
        
        res = @db.select('SELECT * FROM db.keys').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            order_by([:key, :count_all, :count_nodes, :count_ways, :count_relations, :values_all, :users_all], params[:sortname], params[:sortorder]).
            paging(params[:rp], params[:page]).
            execute()

        return {
            :page  => params[:page].to_i,
            :rp    => params[:rp].to_i,
            :total => total,
            :data  => res.map{ |row| {
                :key                      => row['key'],
                :count_all                => row['count_all'].to_i,
                :count_all_fraction       => row['count_all'].to_f / @stats['objects'],
                :count_nodes              => row['count_nodes'].to_i,
                :count_nodes_fraction     => row['count_nodes'].to_f / @stats['nodes_with_tags'],
                :count_ways               => row['count_ways'].to_i,
                :count_ways_fraction      => row['count_ways'].to_f / @stats['ways'],
                :count_relations          => row['count_relations'].to_i,
                :count_relations_fraction => row['count_relations'].to_f / @stats['relations'],
                :values_all               => row['values_all'].to_i,
                :users_all                => row['users_all'].to_i,
                :prevalent_values         => (row['prevalent_values'] || '').split('|').map{ |pv| pv }
            } }
        }.to_json
    end

    get '/api/2/db/keys/overview' do
        key = params[:key]
        out = Hash.new

        # default values
        ['all', 'nodes', 'ways', 'relations'].each do |type|
            out[type] = { :count => 0, :count_fraction => 0.0, :values => 0 }
        end
        out['users'] = 0;

        @db.select('SELECT * FROM db.keys').
            condition('key = ?', key).
            execute() do |row|
                ['all', 'nodes', 'ways', 'relations'].each do |type|
                    out[type] = {
                        :count          => row['count_'  + type].to_i,
                        :count_fraction => row['count_'  + type].to_f / get_total(type),
                        :values         => row['values_' + type].to_i
                    }
                end
                out['users'] = row['users_all'].to_i
        end

        out.to_json
    end

    get '/api/2/db/keys/distribution' do
        key = params[:key]
        content_type :png
        @db.select('SELECT png FROM db.key_distributions').
            condition('key = ?', key).
            get_first_value()
    end

    get '/api/2/db/keys/values' do
        key = params[:key]
        filter_type = get_filter()

        if params[:sortname] == 'count'
            params[:sortname] = 'count_' + filter_type
        end

        (this_key_count, total) = @db.select("SELECT count_#{filter_type} AS count, values_#{filter_type} AS count_values FROM db.keys").
            condition('key = ?', key).
            get_columns(:count, :count_values)

        if params[:query].to_s != ''
            total = @db.count('db.tags').
                condition("count_#{filter_type} > 0").
                condition('key = ?', key).
                condition_if("value LIKE '%' || ? || '%'", params[:query]).
                get_first_value()
        end

        res = @db.select('SELECT * FROM db.tags').
            condition("count_#{filter_type} > 0").
            condition('key = ?', key).
            condition_if("value LIKE '%' || ? || '%'", params[:query]).
            order_by([:value, :count_all, :count_nodes, :count_ways, :count_relations], params[:sortname], params[:sortorder]).
            paging(params[:rp], params[:page]).
            execute()

        return {
            :page  => params[:page].to_i,
            :rp    => params[:rp].to_i,
            :total => total.to_i,
            :data  => res.map{ |row| {
                :value    => row['value'],
                :count    => row['count_' + filter_type].to_i,
                :fraction => row['count_' + filter_type].to_f / this_key_count.to_f
            } }
        }.to_json
    end

    get '/api/2/db/keys/keys' do
        key = params[:key]
        filter_type = get_filter()

        if params[:sortname] == 'to_count'
            params[:sortname] = 'together_count'
        elsif params[:sortname] == 'from_count'
            params[:sortname] = ['from_fraction', 'together_count', 'other_key']
        end

        total = @db.count('db.keypairs').
            condition('key1 = ? OR key2 = ?', key, key).
            condition("count_#{filter_type} > 0").
            get_first_value().to_i

        has_this_key = @db.select("SELECT count_#{filter_type} FROM db.keys").
            condition('key = ?', key).
            get_first_value()

        res = @db.select("SELECT p.key1 AS other_key, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.keypairs p, db.keys k WHERE p.key1=k.key AND p.key2=? AND p.count_#{filter_type} > 0 
                    UNION SELECT p.key2 AS other_key, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.keypairs p, db.keys k WHERE p.key2=k.key AND p.key1=? AND p.count_#{filter_type} > 0", key, key).
            order_by([:together_count, :other_key, :from_fraction], params[:sortname], params[:sortorder]).
            paging(params[:rp], params[:page]).
            execute()

        return {
            :page  => params[:page].to_i,
            :rp    => params[:rp].to_i,
            :total => total,
            :data  => res.map{ |row| {
                :other_key      => row['other_key'],
                :together_count => row['together_count'].to_i,
                :to_fraction    => row['together_count'].to_f / has_this_key.to_f,
                :from_fraction  => row['from_fraction'].to_f
            } }
        }.to_json
    end

    get '/api/2/db/popular_keys' do
        total = @db.count('popular_keys').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            get_first_value().to_i
        
        res = @db.select('SELECT * FROM popular_keys').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            order_by([:key, :scale_count, :scale_users, :scale_wiki, :scale_josm, :scale1, :scale2], params[:sortname], params[:sortorder]).
            paging(params[:rp], params[:page]).
            execute()

        return {
            :page  => params[:page].to_i,
            :rp    => params[:rp].to_i,
            :total => total,
            :data  => res.map{ |row| {
                :key         => row['key'],
                :scale_count => row['scale_count'].to_f,
                :scale_users => row['scale_users'].to_f,
                :scale_wiki  => row['scale_wiki'].to_f,
                :scale_josm  => row['scale_josm'].to_f,
                :scale1      => row['scale1'].to_f,
                :scale2      => row['scale2'].to_f
            } }
        }.to_json
    end

    get '/api/2/db/tags/overview' do
        key   = params[:key]
        value = params[:value]

        out = Hash.new

        # default values
        ['all', 'nodes', 'ways', 'relations'].each do |type|
            out[type] = { :count => 0, :count_fraction => 0.0 }
        end

        @db.select('SELECT * FROM db.tags').
            condition('key = ?', key).
            condition('value = ?', value).
            execute() do |row|
                ['all', 'nodes', 'ways', 'relations'].each do |type|
                    out[type] = {
                        :count          => row['count_'  + type].to_i,
                        :count_fraction => row['count_'  + type].to_f / get_total(type)
                    }
                end
        end

        out.to_json
    end

end
