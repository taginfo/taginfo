# web/lib/api/reports.rb

class Taginfo < Sinatra::Base

    api(2, 'reports/frequently_used_keys_without_wiki_page', {
        :description => 'Return frequently used tag keys that have no associated wiki page.',
        :parameters => {
            :min_count => 'How many tags with this key must there be at least to show up here? (default 10000).',
            :english => 'Check for key wiki pages in any language (0, default) or in the English language (1).',
            :query => 'Only show results where the key matches this query (substring match, optional).'
        },
        :paging => :optional,
        :sort => %w( key count_all values_all users_all ),
        :result => {
            :key                => :STRING,
            :count_all          => :INT,
            :count_all_fraction => :FLOAT,
            :values_all         => :INT,
            :users_all          => :INT,
            :prevalent_values   => [{
                :value    => :STRING,
                :count    => :INT,
                :fraction => :FLOAT
            }]
        },
        :example => { :min_count => 1000, :english => '1', :page => 1, :rp => 10, :sortname => 'count_all', :sortorder => 'desc' },
        :ui => '/reports/frequently_used_keys_without_wiki_page'
    }) do

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

        reshash = Hash.new
        res.each do |row|
            reshash[row['key']] = row
            row['prevalent_values'] = Array.new
        end

        prevvalues = @db.select('SELECT key, value, count, fraction FROM db.prevalent_values').
            condition("key IN (#{ res.map{ |row| "'" + SQLite3::Database.quote(row['key']) + "'" }.join(',') })").
            order_by([:count], 'DESC').
            execute()

        prevvalues.each do |pv|
            key = pv['key']
            pv.delete_if{ |k,v| k.is_a?(Integer) || k == 'key' }
            pv['count'] = pv['count'].to_i
            pv['fraction'] = pv['fraction'].to_f
            reshash[key]['prevalent_values'] << pv
        end

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
                :prevalent_values   => row['prevalent_values']
            } }
        }.to_json
    end

    api(2, 'reports/languages', {
        :description => 'List languages Taginfo knows about and how many wiki pages describing keys and tags there are in these languages.',
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
            order_by(params[:sortname], params[:sortorder]){ |o|
                o.code
                o.native_name
                o.english_name
                o.wiki_key_pages
                o.wiki_tag_pages
            }.
            execute()

        return {
            :page  => 1,
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
