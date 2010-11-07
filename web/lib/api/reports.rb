# lib/api/reports.rb

class Taginfo < Sinatra::Base

    get '/api/2/reports/frequently_used_keys_without_wiki_page' do

        min_count = params[:min_count].to_i || 10000

        english = (params[:english] == '1') ? '_en' : ''

        total = @db.count('db.keys').
            condition('count_all > ?', min_count).
            condition("in_wiki#{english} = 0").
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            get_first_value().to_i
        
        res = @db.select('SELECT * FROM db.keys').
            condition('count_all > ?', min_count).
            condition("in_wiki#{english} = 0").
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            order_by(params[:sortname], params[:sortorder]){ |o|
                o.key
                o.count_all
                o.values_all
                o.users_all
            }.
            paging(params[:rp], params[:page]).
            execute()

        return {
            :page  => params[:page].to_i,
            :rp    => params[:rp].to_i,
            :total => total,
            :data  => res.map{ |row| {
                :key                => row['key'],
                :count_all          => row['count_all'].to_i,
                :count_all_fraction => row['count_all'].to_f / @db.stats('objects'),
                :values_all         => row['values_all'].to_i,
                :users_all          => row['users_all'].to_i,
                :prevalent_values   => (row['prevalent_values'] || '').split('|').map{ |pv| pv }
            } }
        }.to_json
    end

end
