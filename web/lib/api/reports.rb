# lib/api/reports.rb

class Taginfo < Sinatra::Base

    get '/api/2/reports/frequently_used_keys_without_wiki_page' do
        min_count = params[:min_count].to_i || 10000
        total = @db.count('db.keys').
            condition('count_all > ?', min_count).
            condition('in_wiki = 0').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            get_first_value().to_i
        
        res = @db.select('SELECT * FROM db.keys').
            condition('count_all > ?', min_count).
            condition('in_wiki = 0').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            order_by([:key, :count_all, :values_all, :users_all], params[:sortname], params[:sortorder]).
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
                :values_all               => row['values_all'].to_i,
                :users_all                => row['users_all'].to_i,
                :prevalent_values         => (row['prevalent_values'] || '').split('|').map{ |pv| pv }
            } }
        }.to_json
    end

end
