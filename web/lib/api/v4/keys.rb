# web/lib/api/v4/keys.rb
class Taginfo < Sinatra::Base

    @@filters = {
        :characters_plain       => { :expr => "characters='plain'",   :doc => 'Category A: Only show keys with latin lowercase letters (a to z) or underscore (_), first and last characters must be letters.' },
        :characters_colon       => { :expr => "characters='colon'",   :doc => 'Category B: Only show keys like category A but with one ore more colons (:) inside.' },
        :characters_letters     => { :expr => "characters='letters'", :doc => 'Category C: Only show keys like category B but with uppercase latin letters or letters from other scripts.' },
        :characters_space       => { :expr => "characters='space'",   :doc => 'Category D: Only show keys with at least one whitespace character (space, tab, new line, carriage return, or from other scripts).' },
        :characters_problem     => { :expr => "characters='problem'", :doc => 'Category E: Only show keys with problematic characters.' },
        :characters_rest        => { :expr => "characters='rest'",    :doc => 'Category F: Only show keys not fitting in category A through E.' },
        :in_wiki                => { :expr => "in_wiki=1",            :doc => 'Only show keys that appear in the wiki.' },
        :not_in_db              => { :expr => "count_all=0",          :doc => 'Only show keys that do not appear in the database.' }
    }

    api(4, 'keys/all', {
        :description => 'Get list of all keys.',
        :parameters => { :query => 'Only show keys matching this query (substring match, optional).' },
        :paging => :optional,
        :filter => @@filters,
        :sort => %w[ key count_all count_nodes count_ways count_relations values_all users_all in_wiki length ],
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
            [:in_wiki,                  :BOOL,   'Is there at least one wiki page for this key?'],
            [:projects,                 :INT,    'Number of projects using this key']
        ]),
        :example => { :page => 1, :rp => 10, :filter => 'in_wiki', :sortname => 'key', :sortorder => 'asc' },
        :ui => '/keys'
    }) do

        if params[:filter]
            filters = params[:filter].split(',').map{ |f| @@filters[f.to_sym] ? @@filters[f.to_sym][:expr] : nil }.compact
        elsif params[:filters] # old param name for backwards compatibility
            filters = params[:filters].split(',').map{ |f| @@filters[f.to_sym] ? @@filters[f.to_sym][:expr] : nil }.compact
        else
            filters = []
        end

        include_data = Hash.new
        if params[:include]
            params[:include].split(',').each{ |inc| include_data[inc.to_sym] = 1 }
        end

        total = @db.count('db.keys').
            condition_if("key LIKE ? ESCAPE '@'", like_contains(params[:query])).
            conditions(filters).
            get_first_i

        res = @db.select('SELECT * FROM db.keys').
            condition_if("key LIKE ? ESCAPE '@'", like_contains(params[:query])).
            conditions(filters).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.key
                o.count_all
                o.count_nodes
                o.count_ways
                o.count_relations
                o.values_all
                o.users_all
                o.in_wiki
                o.projects
                o.projects :key
                o.length 'length(key)'
                o.length :key
            end.
            paging(@ap).
            execute

        if include_data[:wikipages]
            reshash = Hash.new
            res.each do |row|
                reshash[row['key']] = row
                row['wikipages'] = Array.new
            end

            key_list = res.map do |row|
                "'" + SQLite3::Database.quote(row['key']) + "'"
            end

            wikipages = @db.select('SELECT key, lang, title, type FROM wiki.wikipages').
                condition("key IN (#{ key_list.join(',') }) AND value IS NULL").
                order_by([:key, :lang], 'ASC').
                execute

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

            key_list = res.map do |row|
                "'" + SQLite3::Database.quote(row['key']) + "'"
            end

            prevvalues = @db.select('SELECT key, value, count, fraction FROM db.prevalent_values').
                condition("key IN (#{ key_list.join(',') })").
                order_by([:count], 'DESC').
                execute

            prevvalues.each do |pv|
                key = pv['key']
                pv.delete_if{ |k,v| k.is_a?(Integer) || k == 'key' }
                pv['count'] = pv['count'].to_i
                pv['fraction'] = pv['fraction'].to_f
                reshash[key]['prevalent_values'] << pv
            end
        end

        return generate_json_result(total,
            res.map do |row| h = {
                    :key                      => row['key'],
                    :count_all                => row['count_all'].to_i,
                    :count_all_fraction       => (row['count_all'].to_f / @db.stats('objects')).round(4),
                    :count_nodes              => row['count_nodes'].to_i,
                    :count_nodes_fraction     => (row['count_nodes'].to_f / @db.stats('nodes_with_tags')).round(4),
                    :count_ways               => row['count_ways'].to_i,
                    :count_ways_fraction      => (row['count_ways'].to_f / @db.stats('ways')).round(4),
                    :count_relations          => row['count_relations'].to_i,
                    :count_relations_fraction => (row['count_relations'].to_f / @db.stats('relations')).round(4),
                    :values_all               => row['values_all'].to_i,
                    :users_all                => row['users_all'].to_i,
                    :in_wiki                  => row['in_wiki'].to_i != 0,
                    :projects                 => row['projects'].to_i
                }
                h[:wikipages] = row['wikipages'] if row['wikipages']
                h[:prevalent_values] = row['prevalent_values'][0, 10] if row['prevalent_values']
                h
            end
        )
    end

    api(4, 'keys/wiki_pages', {
        :description => 'Get list of wiki pages in different languages for all keys.',
        :parameters => { :query => 'Only show keys matching this query (substring match, optional).' },
        :paging => :optional,
        :sort => %w[ key ],
        :result => paging_results([
            [:key, :STRING, 'Key'],
            [:lang, :HASH, 'Hash with language codes as keys and values showing what type of wiki pages are available.']
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'key', :sortorder => 'asc' },
        :ui => '/reports/language_comparison_table_for_keys_in_the_wiki'
    }) do
        total = @db.count('wiki.wikipages_keys').
            condition_if("key LIKE ? ESCAPE '@'", like_contains(params[:query])).
            get_first_i

        res = @db.select("SELECT key, coalesce(langs, '') AS langs FROM wiki.wikipages_keys").
            condition_if("key LIKE ? ESCAPE '@'", like_contains(params[:query])).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.key
            end.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row|
                lang_hash = Hash.new
                row['langs'].split(',').each do |l|
                    (lang, status) = l.split(' ', 2)
                    lang_hash[lang] = status
                end
                { :key => row['key'], :lang => lang_hash }
            end
        )
    end

    api(4, 'keys/similar', {
        :description => 'Get list of pairs of similar keys, one used very often, one used rarely.',
        :parameters => { :query => 'Only show keys matching this query (substring match, optional).' },
        :paging => :optional,
        :sort => %w[ key_common key_rare count_all_common count_all_rare similarity ],
        :result => paging_results([
            [:key_common,       :STRING, 'Key thats used often in OSM database'],
            [:count_all_common, :INT,    'Number of objects in the OSM database with the common key.'],
            [:key_rare,         :STRING, 'Key thats used rarely in OSM database'],
            [:count_all_rare,   :INT,    'Number of objects in the OSM database with the rare key.'],
            [:similarity,       :INT,    'An integer measuring the similarity of the two keys, smaller is more similar.']
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'count_all_common', :sortorder => 'desc' },
        :ui => '/reports/similar_keys'
    }) do
        query = like_contains(params[:query])

        cond = "(similarity != 0 OR lower(key_common) = lower(key_rare)) AND count_all_common >= 10000"

        total = @db.count('similar_keys_common_rare').
            condition(cond).
            condition_if("(key_common LIKE ? ESCAPE '@' OR key_rare LIKE ? ESCAPE '@')", query, query).
            get_first_i

        res = @db.select("SELECT * FROM similar_keys_common_rare").
            condition(cond).
            condition_if("(key_common LIKE ? ESCAPE '@' OR key_rare LIKE ? ESCAPE '@')", query, query).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.key_common :key_common
                o.key_common :key_rare
                o.key_rare :key_rare
                o.key_rare :key_common
                o.count_all_common :count_all_common
                o.count_all_common! :count_all_rare
                o.count_all_common! :similarity
                o.count_all_rare :count_all_rare
                o.count_all_rare! :count_all_common
                o.count_all_rare :similarity
                o.similarity :similarity
                o.similarity! :count_all_common
                o.similarity! :count_all_rare
            end.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                    :key_common       => row['key_common'],
                    :key_rare         => row['key_rare'],
                    :count_all_common => row['count_all_common'],
                    :count_all_rare   => row['count_all_rare'],
                    :similarity       => row['similarity']
                }
            end
        )
    end

    api(4, 'keys/without_wiki_page', {
        :description => 'Return frequently used tag keys that have no associated wiki page.',
        :parameters => {
            :min_count => 'How many tags with this key must there be at least to show up here? (default 10000).',
            :english => 'Check for key wiki pages in any language (0, default) or in the English language (1).',
            :query => 'Only show results where the key matches this query (substring match, optional).'
        },
        :paging => :optional,
        :sort => %w[ key count_all values_all users_all ],
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
            condition_if("key LIKE ? ESCAPE '@'", like_contains(params[:query])).
            get_first_i

        res = @db.select('SELECT * FROM db.keys').
            condition('count_all > ?', min_count).
            condition("in_wiki#{english} = 0").
            condition_if("key LIKE ? ESCAPE '@'", like_contains(params[:query])).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.key
                o.count_all
                o.values_all
                o.users_all
            end.
            paging(@ap).
            execute

        reshash = Hash.new
        res.each do |row|
            reshash[row['key']] = row
            row['prevalent_values'] = Array.new
        end

        prevvalues = @db.select('SELECT key, value, count, fraction FROM db.prevalent_values').
            condition("key IN (#{ res.map{ |row| "'" + SQLite3::Database.quote(row['key']) + "'" }.join(',') })").
            order_by([:count], 'DESC').
            execute

        prevvalues.each do |pv|
            key = pv['key']
            pv.delete_if{ |k,v| k.is_a?(Integer) || k == 'key' }
            pv['count'] = pv['count'].to_i
            pv['fraction'] = pv['fraction'].to_f
            reshash[key]['prevalent_values'] << pv
        end

        return generate_json_result(total,
            res.map do |row| {
                :key                => row['key'],
                :count_all          => row['count_all'].to_i,
                :count_all_fraction => row['count_all'].to_f / @db.stats('objects'),
                :values_all         => row['values_all'].to_i,
                :users_all          => row['users_all'].to_i,
                :prevalent_values   => row['prevalent_values']
            }
            end
        )
    end

end
