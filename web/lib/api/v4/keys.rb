# web/lib/api/v4/keys.rb
class Taginfo < Sinatra::Base

    @@filters = {
        :characters_space       => { :expr => "characters='space'",   :doc => 'Only show keys with spaces.' },
        :characters_problematic => { :expr => "characters='problem'", :doc => 'Only show keys with problematic characters.' },
        :in_wiki                => { :expr => "in_wiki=1",            :doc => 'Only show keys that appear in the wiki.' },
        :not_in_db              => { :expr => "count_all=0",          :doc => 'Only show keys that do not appear in the database.' }
    }

    api(4, 'keys/all', {
        :description => 'Get list of all keys.',
        :parameters => { :query => 'Only show keys matching this query (substring match, optional).' },
        :paging => :optional,
        :filter => @@filters,
        :sort => %w( key count_all count_nodes count_ways count_relations values_all users_all in_wiki in_josm in_potlatch length ),
        :result => paging_results([
            [:key,                      :STRING, 'Key'],
            [:count_all,                :INT,    'Number of objects in the OSM database with this key.'],
            [:count_all_fraction,       :FLOAT,  'Number of objects in relation to all objects.'],
            [:count_nodes,              :INT,    'Number of nodes in the OSM database with this key.'],
            [:count_nodes_fraction,     :FLOAT,  'Number of nodes in relation to all tagged nodes.'],
            [:count_ways,               :INT,    'Number of ways in the OSM database with this key.'],
            [:count_ways_fraction,      :FLOAT,  'Number of ways in relation to all ways.'],
            [:count_relations,          :INT,    'Number of relations in the OSM database with this key.'],
            [:count_relations_fraction, :FLOAT,  'Number of relations in relation to all relations.'],
            [:values_all,               :INT,    'Number of different values for this key.'],
            [:users_all,                :INT,    'Number of users owning objects with this key.'],
            [:in_wiki,                  :BOOL,   'Has this key at least one wiki page?'],
            [:in_josm,                  :BOOL,   'Is this key referenced in at least one JOSM style rule?']
        ]),
        :example => { :page => 1, :rp => 10, :filter => 'in_wiki', :sortname => 'key', :sortorder => 'asc' },
        :ui => '/keys'
    }) do

        if params[:filters]
            filters = params[:filters].split(',').map{ |f| @@filters[f.to_sym][:expr] }.compact
        else
            filters = []
        end

        include_data = Hash.new
        if params[:include]
            params[:include].split(',').each{ |inc| include_data[inc.to_sym] = 1 }
        end

        total = @db.count('db.keys').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            conditions(filters).
            get_first_value().to_i
        
        res = @db.select('SELECT * FROM db.keys').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            conditions(filters).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.key
                o.count_all
                o.count_nodes
                o.count_ways
                o.count_relations
                o.values_all
                o.users_all
                o.in_wiki
                o.in_josm
                o.in_potlatch
                o.length 'length(key)'
                o.length :key
            }.
            paging(@ap).
            execute()

        if include_data[:wikipages]
            reshash = Hash.new
            res.each do |row|
                reshash[row['key']] = row
                row['wikipages'] = Array.new
            end

            wikipages = @db.select('SELECT key, lang, title, type FROM wiki.wikipages').
                condition("value IS NULL").
                condition("key IN (#{ res.map{ |row| "'" + SQLite3::Database.quote(row['key']) + "'" }.join(',') })").
                order_by([:key, :lang], 'ASC').
                execute()

            wikipages.each do |wp|
                key = wp['key']
                wp.delete_if{ |k,v| k.is_a?(Integer) || k == 'key' }
                reshash[key]['wikipages'] << wp
            end
        end

        if include_data[:prevalent_values]
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
        end

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map{ |row| h = {
                :key                      => row['key'],
                :count_all                => row['count_all'].to_i,
                :count_all_fraction       => (row['count_all'].to_f / @db.stats('objects')).round_to(4),
                :count_nodes              => row['count_nodes'].to_i,
                :count_nodes_fraction     => (row['count_nodes'].to_f / @db.stats('nodes_with_tags')).round_to(4),
                :count_ways               => row['count_ways'].to_i,
                :count_ways_fraction      => (row['count_ways'].to_f / @db.stats('ways')).round_to(4),
                :count_relations          => row['count_relations'].to_i,
                :count_relations_fraction => (row['count_relations'].to_f / @db.stats('relations')).round_to(4),
                :values_all               => row['values_all'].to_i,
                :users_all                => row['users_all'].to_i,
                :in_wiki                  => row['in_wiki'].to_i     == 1 ? true : false,
                :in_josm                  => row['in_josm'].to_i     == 1 ? true : false
            } 
            h[:wikipages] = row['wikipages'] if row['wikipages']
            h[:prevalent_values] = row['prevalent_values'][0,10] if row['prevalent_values']
            h }
        }.to_json
    end

    api(4, 'keys/wiki_pages', {
        :description => 'Get list of wiki pages in different languages for all keys.',
        :parameters => { :query => 'Only show keys matching this query (substring match, optional).' },
        :paging => :optional,
        :sort => %w( key ),
        :result => paging_results([
            [:key, :STRING, 'Key'], 
            [:lang, :HASH, 'Hash with language codes as keys and values showing what type of wiki pages are available.']
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'key', :sortorder => 'asc' },
        :ui => '/reports/language_comparison_table_for_keys_in_the_wiki'
    }) do
        languages = @db.execute('SELECT language FROM wiki.wiki_languages ORDER by language').map do |row|
            row['language']
        end

        total = @db.count('wiki.wikipages_keys').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            get_first_value().to_i

        res = @db.select('SELECT key, langs FROM wiki.wikipages_keys').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            order_by(@ap.sortname, @ap.sortorder){ |o|
                o.key
            }.
            paging(@ap).
            execute()

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map{ |row|
                lang_hash = Hash.new
                row['langs'].split(',').each{ |l|
                    (lang, status) = l.split(' ', 2)
                    lang_hash[lang] = status
                }
                { :key => row['key'], :lang => lang_hash }
            }
        }.to_json
    end

    api(4, 'keys/without_wiki_page', {
        :description => 'Return frequently used tag keys that have no associated wiki page.',
        :parameters => {
            :min_count => 'How many tags with this key must there be at least to show up here? (default 10000).',
            :english => 'Check for key wiki pages in any language (0, default) or in the English language (1).',
            :query => 'Only show results where the key matches this query (substring match, optional).'
        },
        :paging => :optional,
        :sort => %w( key count_all values_all users_all ),
        :result => paging_results([
            [:key,                :STRING, 'Key'],
            [:count_all,          :INT,    'Number of objects in database with this key.'],
            [:count_all_fraction, :FLOAT,  'Fraction of objects in database with this key.'],
            [:values_all,         :INT,    'Number of different values for this key.'],
            [:users_all,          :INT,    'Number of different users who own objects with this key.'],
            [:prevalent_values,   :HASH,   'Often used values.', [
                [:value,    :STRING, 'Value'],
                [:count,    :INT,    'Number of occurances of this value.'],
                [:fraction, :FLOAT,  'Fraction of all values.']
            ]]
        ]),
        :example => { :min_count => 1000, :english => '1', :page => 1, :rp => 10, :sortname => 'count_all', :sortorder => 'desc' },
        :ui => '/reports/frequently_used_keys_without_wiki_page'
    }) do

        min_count = params[:min_count].to_i
        if min_count == 0
            min_count = 10000
        end

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
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.key
                o.count_all
                o.values_all
                o.users_all
            }.
            paging(@ap).
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
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
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

end
