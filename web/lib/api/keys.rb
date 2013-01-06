# web/lib/api/keys.rb
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
        :result => {
            :key                      => :STRING, 
            :count_all                => :INT,
            :count_all_fraction       => :FLOAT,
            :count_nodes              => :INT,
            :count_nodes_fraction     => :FLOAT,
            :count_ways               => :INT,
            :count_ways_fraction      => :FLOAT,
            :count_relations          => :INT,
            :count_relations_fraction => :FLOAT,
            :values_all               => :INT,
            :users_all                => :INT,
            :in_wiki                  => :BOOL,
            :in_josm                  => :BOOL,
            :in_potlatch              => :BOOL
        },
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
                :in_josm                  => row['in_josm'].to_i     == 1 ? true : false,
                :in_potlatch              => row['in_potlatch'].to_i == 1 ? true : false,
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
        :result => {
            :key  => :STRING, 
            :lang => "Hash with language codes as keys and values showing what type of wiki page is available"
        },
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

end
