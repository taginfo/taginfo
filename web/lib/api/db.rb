# web/lib/api/db.rb
class Taginfo < Sinatra::Base

    @@filters = {
        :characters_space       => { :expr => "characters='space'",   :doc => 'Only show keys with spaces.' },
        :characters_problematic => { :expr => "characters='problem'", :doc => 'Only show keys with problematic characters.' },
        :in_wiki                => { :expr => "in_wiki=1",            :doc => 'Only show keys that appear in the wiki.' },
        :not_in_db              => { :expr => "count_all=0",          :doc => 'Only show keys that do not appear in the database.' }
    }

    api(2, 'db/keys', {
        :superseded_by => '4/keys/all',
        :description => 'Get list of keys that are in the database or mentioned in any other source.',
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

    api(2, 'db/tags', {
        :superseded_by => '4/tags/popular',
        :description => 'Get list of most often used tags.',
        :parameters => { :query => 'Only show tags matching this query (substring match in key and value, optional).' },
        :paging => :optional,
        :sort => %w( tag count_all count_nodes count_ways count_relations ),
        :result => {
            :key                      => :STRING, 
            :value                    => :STRING, 
            :count_all                => :INT,
            :count_all_fraction       => :FLOAT,
            :count_nodes              => :INT,
            :count_nodes_fraction     => :FLOAT,
            :count_ways               => :INT,
            :count_ways_fraction      => :FLOAT,
            :count_relations          => :INT,
            :count_relations_fraction => :FLOAT,
        },
        :example => { :page => 1, :rp => 10, :sortname => 'tag', :sortorder => 'asc' },
        :ui => '/tags'
    }) do

        total = @db.count('db.selected_tags').
            condition_if("(skey LIKE '%' || ? || '%') OR (svalue LIKE '%' || ? || '%')", params[:query], params[:query]).
            get_first_value().to_i
        
        res = @db.select('SELECT * FROM db.selected_tags').
            condition_if("(skey LIKE '%' || ? || '%') OR (svalue LIKE '%' || ? || '%')", params[:query], params[:query]).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.tag :skey
                o.tag :svalue
                o.count_all
                o.count_nodes
                o.count_ways
                o.count_relations
            }.
            paging(@ap).
            execute()

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map{ |row| {
                :key                      => row['skey'],
                :value                    => row['svalue'],
                :count_all                => row['count_all'].to_i,
                :count_all_fraction       => (row['count_all'].to_f / @db.stats('objects')).round_to(4),
                :count_nodes              => row['count_nodes'].to_i,
                :count_nodes_fraction     => (row['count_nodes'].to_f / @db.stats('nodes_with_tags')).round_to(4),
                :count_ways               => row['count_ways'].to_i,
                :count_ways_fraction      => (row['count_ways'].to_f / @db.stats('ways')).round_to(4),
                :count_relations          => row['count_relations'].to_i,
                :count_relations_fraction => (row['count_relations'].to_f / @db.stats('relations')).round_to(4),
            } }
        }.to_json
    end

    api(2, 'db/keys/overview', {
        :superseded_by => '4/key/stats',
        :description => 'Show statistics for nodes, ways, relations and total for this key.',
        :parameters => { :key => 'Tag key (required).' },
        :paging => :no,
        :result => {
            :nodes => {
                :count => :INT,
                :count_fraction => :FLOAT,
                :values => :INT
            },
            :ways => {
                :count => :INT,
                :count_fraction => :FLOAT,
                :values => :INT
            },
            :relations => {
                :count => :INT,
                :count_fraction => :FLOAT,
                :values => :INT
            },
            :all => {
                :count => :INT,
                :count_fraction => :FLOAT,
                :values => :INT
            },
            :users => :INT
        },
        :example => { :key => 'highway' },
        :ui => '/keys/highway'
    }) do
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
                        :count_fraction => (row['count_'  + type].to_f / get_total(type)).round_to(4),
                        :values         => row['values_' + type].to_i
                    }
                end
                out['users'] = row['users_all'].to_i
        end

        out.to_json
    end

    api(3, 'db/keys/overview') do
        key = params[:key]
        out = []

        # default values
        ['all', 'nodes', 'ways', 'relations'].each_with_index do |type, n|
            out[n] = { :type => type, :count => 0, :count_fraction => 0.0, :values => 0 }
        end

        @db.select('SELECT * FROM db.keys').
            condition('key = ?', key).
            execute() do |row|
                ['all', 'nodes', 'ways', 'relations'].each_with_index do |type, n|
                    out[n] = {
                        :type           => type,
                        :count          => row['count_'  + type].to_i,
                        :count_fraction => (row['count_'  + type].to_f / get_total(type)).round_to(4),
                        :values         => row['values_' + type].to_i
                    }
                end
        end

        out.to_json
    end

    api(2, 'db/keys/distribution', {
        :superseded_by => '4/key/distribution/nodes',
        :description => 'Get map with distribution of this key in the database (nodes only).',
        :parameters => { :key => 'Tag key (required).' },
        :result => 'PNG image.',
        :example => { :key => 'amenity' },
        :ui => '/keys/highway#map'
    }) do
        key = params[:key]
        content_type :png
        @db.select('SELECT png FROM db.key_distributions').
            condition("object_type='n'").
            condition('key = ?', key).
            get_first_value() ||
        @db.select('SELECT png FROM db.key_distributions').
            condition('key IS NULL').
            get_first_value()
    end

    api(3, 'db/keys/distribution/nodes', {
        :superseded_by => '4/key/distribution/nodes',
        :description => 'Get map with distribution of this key in the database (nodes only).',
        :parameters => { :key => 'Tag key (required).' },
        :result => 'PNG image.',
        :example => { :key => 'amenity' },
        :ui => '/keys/amenity#map'
    }) do
        key = params[:key]
        content_type :png
        @db.select('SELECT png FROM db.key_distributions').
            condition("object_type='n'").
            condition('key = ?', key).
            get_first_value() ||
        @db.select('SELECT png FROM db.key_distributions').
            condition('key IS NULL').
            get_first_value()
    end

    api(3, 'db/keys/distribution/ways', {
        :superseded_by => '4/key/distribution/ways',
        :description => 'Get map with distribution of this key in the database (ways only).',
        :parameters => { :key => 'Tag key (required).' },
        :result => 'PNG image.',
        :example => { :key => 'highway' },
        :ui => '/keys/highway#map'
    }) do
        key = params[:key]
        content_type :png
        @db.select('SELECT png FROM db.key_distributions').
            condition("object_type='w'").
            condition('key = ?', key).
            get_first_value() ||
        @db.select('SELECT png FROM db.key_distributions').
            condition('key IS NULL').
            get_first_value()
    end

    api(2, 'db/keys/values', {
        :superseded_by => '4/key/values',
        :description => 'Get values used with a given key.',
        :parameters => {
            :key => 'Tag key (required).',
            :lang => "Language (optional, default: 'en').",
            :query => 'Only show results where the value matches this query (substring match, optional).'
        },
        :paging => :optional,
        :filter => {
            :all       => { :doc => 'No filter.' },
            :nodes     => { :doc => 'Only values on tags used on nodes.' },
            :ways      => { :doc => 'Only values on tags used on ways.' },
            :relations => { :doc => 'Only values on tags used on relations.' }
        },
        :sort => %w( value count_all count_nodes count_ways count_relations ),
        :result => { :value => :STRING, :count => :INT, :fraction => :FLOAT, :description => :STRING },
        :example => { :key => 'highway', :page => 1, :rp => 10, :sortname => 'count_ways', :sortorder => 'desc' },
        :ui => '/keys/highway#values'
    }) do
        key = params[:key]
        lang = params[:lang] || 'en'
        filter_type = get_filter()

        if @ap.sortname == 'count'
            @ap.sortname = ['count_' + filter_type]
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
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.value
                o.count_all
                o.count_nodes
                o.count_ways
                o.count_relations
            }.
            paging(@ap).
            execute()

        # Read description for tag from wikipages, first in English then in the chosen
        # language. This way the chosen language description will overwrite the default
        # English one.
        wikidesc = {}
        ['en', lang].uniq.each do |lang|
            @db.select('SELECT value, description FROM wiki.wikipages').
                condition('lang = ?', lang).
                condition('key = ?', key).
                condition("value IN (#{ res.map{ |row| "'" + SQLite3::Database.quote(row['value']) + "'" }.join(',') })").
                execute().each do |row|
                wikidesc[row['value']] = row['description']
            end
        end

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total.to_i,
            :data  => res.map{ |row| {
                :value    => row['value'],
                :count    => row['count_' + filter_type].to_i,
                :fraction => (row['count_' + filter_type].to_f / this_key_count.to_f).round_to(4),
                :description => wikidesc[row['value']]
            } }
        }.to_json
    end

    api(2, 'db/keys/keys', {
        :superseded_by => '4/key/combinations',
        :description => 'Find keys that are used together with a given key.',
        :parameters => {
            :key => 'Tag key (required).',
            :query => 'Only show results where the other_key matches this query (substring match, optional).'
        },
        :paging => :optional,
        :filter => {
            :all       => { :doc => 'No filter.' },
            :nodes     => { :doc => 'Only values on tags used on nodes.' },
            :ways      => { :doc => 'Only values on tags used on ways.' },
            :relations => { :doc => 'Only values on tags used on relations.' }
        },
        :sort => %w( together_count other_key from_fraction ),
        :result => {
            :other_key      => :STRING,
            :together_count => :INT,
            :to_fraction    => :FLOAT,
            :from_fraction  => :FLOAT
        },
        :example => { :key => 'highway', :page => 1, :rp => 10, :sortname => 'together_count', :sortorder => 'desc' },
        :ui => '/keys/highway#keys'
    }) do
        key = params[:key]
        filter_type = get_filter()

        if @ap.sortname == 'to_count'
            @ap.sortname = ['together_count']
        elsif @ap.sortname == 'from_count'
            @ap.sortname = ['from_fraction', 'together_count', 'other_key']
        end

        cq = @db.count('db.key_combinations')
        total = (params[:query].to_s != '' ? cq.condition("(key1 = ? AND key2 LIKE '%' || ? || '%') OR (key2 = ? AND key1 LIKE '%' || ? || '%')", key, params[:query], key, params[:query]) : cq.condition('key1 = ? OR key2 = ?', key, key)).
            condition("count_#{filter_type} > 0").
            get_first_value().to_i

        has_this_key = @db.select("SELECT count_#{filter_type} FROM db.keys").
            condition('key = ?', key).
            get_first_value()

        res = (params[:query].to_s != '' ?
            @db.select("SELECT p.key1 AS other_key, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.key_combinations p, db.keys k WHERE p.key1=k.key AND p.key2=? AND (p.key1 LIKE '%' || ? || '%') AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.key_combinations p, db.keys k WHERE p.key2=k.key AND p.key1=? AND (p.key2 LIKE '%' || ? || '%') AND p.count_#{filter_type} > 0", key, params[:query], key, params[:query]) :
            @db.select("SELECT p.key1 AS other_key, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.key_combinations p, db.keys k WHERE p.key1=k.key AND p.key2=? AND p.count_#{filter_type} > 0 
                    UNION SELECT p.key2 AS other_key, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.key_combinations p, db.keys k WHERE p.key2=k.key AND p.key1=? AND p.count_#{filter_type} > 0", key, key)).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.together_count
                o.other_key
                o.from_fraction
            }.
            paging(@ap).
            execute()

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map{ |row| {
                :other_key      => row['other_key'],
                :together_count => row['together_count'].to_i,
                :to_fraction    => (row['together_count'].to_f / has_this_key.to_f).round_to(4),
                :from_fraction  => row['from_fraction'].to_f.round_to(4)
            } }
        }.to_json
    end

    api(2, 'db/popular_keys') do
        total = @db.count('popular_keys').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            get_first_value().to_i
        
        res = @db.select('SELECT * FROM popular_keys').
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.key
                o.scale_count
                o.scale_user
                o.scale_wiki
                o.scale_josm
                o.scale1
                o.scale2
            }.
            paging(@ap).
            execute()

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
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

    api(2, 'db/tags/overview', {
        :superseded_by => '4/tag/stats',
        :description => 'Show statistics for nodes, ways, relations and total for this tag.',
        :parameters => {
            :key => 'Tag key (required).',
            :value => 'Tag value (required).'
        },
        :paging => :no,
        :result => {
            :nodes => {
                :count => :INT,
                :count_fraction => :FLOAT,
            },
            :ways => {
                :count => :INT,
                :count_fraction => :FLOAT,
            },
            :relations => {
                :count => :INT,
                :count_fraction => :FLOAT,
            },
            :all => {
                :count => :INT,
                :count_fraction => :FLOAT,
            }
        },
        :example => { :key => 'highway', :value => 'residential' },
        :ui => '/tags/highway=residential'
    }) do
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
                        :count_fraction => (row['count_'  + type].to_f / get_total(type)).round_to(4)
                    }
                end
        end

        out.to_json
    end

    api(3, 'db/tags/overview') do
        key = params[:key]
        value = params[:value]
        out = []

        # default values
        ['all', 'nodes', 'ways', 'relations'].each_with_index do |type, n|
            out[n] = { :type => type, :count => 0, :count_fraction => 0.0 }
        end

        @db.select('SELECT * FROM db.tags').
            condition('key = ?', key).
            condition('value = ?', value).
            execute() do |row|
                ['all', 'nodes', 'ways', 'relations'].each_with_index do |type, n|
                    out[n] = {
                        :type           => type,
                        :count          => row['count_'  + type].to_i,
                        :count_fraction => (row['count_'  + type].to_f / get_total(type)).round_to(4)
                    }
                end
        end

        out.to_json
    end

    api(2, 'db/tags/combinations', {
        :superseded_by => '4/tag/combinations',
        :description => 'Find keys and tags that are used together with a given tag.',
        :parameters => {
            :key => 'Tag key (required).',
            :value => 'Tag value (required).',
            :query => 'Only show results where the other_key or other_value matches this query (substring match, optional).'
        },
        :paging => :optional,
        :filter => {
            :all       => { :doc => 'No filter.' },
            :nodes     => { :doc => 'Only values on tags used on nodes.' },
            :ways      => { :doc => 'Only values on tags used on ways.' },
            :relations => { :doc => 'Only values on tags used on relations.' }
        },
        :sort => %w( together_count other_tag from_fraction ),
        :result => {
            :other_key      => :STRING,
            :other_value    => :STRING,
            :together_count => :INT,
            :to_fraction    => :FLOAT,
            :from_fraction  => :FLOAT
        },
        :example => { :key => 'highway', :value => 'residential', :page => 1, :rp => 10, :sortname => 'together_count', :sortorder => 'desc' },
        :ui => '/tags/highway=residential#combinations'
    }) do
        key = params[:key]
        value = params[:value]
        filter_type = get_filter()

        if @ap.sortname == 'to_count'
            @ap.sortname = ['together_count']
        elsif @ap.sortname == 'from_count'
            @ap.sortname = ['from_fraction', 'together_count', 'other_key', 'other_value']
        elsif @ap.sortname == 'other_tag'
            @ap.sortname = ['other_key', 'other_value']
        end

        cq = @db.count('db.tag_combinations')
        total = (params[:query].to_s != '' ?
                cq.condition("(key1=? AND value1=? AND (key2 LIKE '%' || ? || '%' OR value2 LIKE '%' || ? || '%')) OR (key2=? AND value2=? AND (key1 LIKE '%' || ? || '%' OR value2 LIKE '%' || ? || '%'))",
                    key, value, params[:query], params[:query], key, value, params[:query], params[:query]) :
                cq.condition('(key1=? AND value1=?) OR (key2=? AND value2=?)', key, value, key, value)).
            condition("count_#{filter_type} > 0").
            get_first_value().to_i

        has_this_key = @db.select("SELECT count_#{filter_type} FROM db.tags").
            condition('key = ?', key).
            condition('value = ?', value).
            get_first_value()

        res = (params[:query].to_s != '' ?
            @db.select("SELECT p.key1 AS other_key, p.value1 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.selected_tags k WHERE p.key1=k.skey AND p.value1=k.svalue AND k.svalue != '' AND p.key2=? AND p.value2=? AND ((p.key1 LIKE '%' || ? || '%') OR (p.value1 LIKE '%' || ? || '%')) AND p.count_#{filter_type} > 0
                    UNION SELECT p.key1 AS other_key, p.value1 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.keys k WHERE p.key1=k.key AND p.value1='' AND p.key2=? AND p.value2=? AND ((p.key1 LIKE '%' || ? || '%') OR (p.value1 LIKE '%' || ? || '%')) AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, p.value2 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.selected_tags k WHERE p.key2=k.skey AND p.value2=k.svalue AND k.svalue != '' AND p.key1=? AND p.value1=? AND ((p.key2 LIKE '%' || ? || '%') OR (p.value2 LIKE '%' || ? || '%')) AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, p.value2 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.keys k WHERE p.key2=k.key AND p.value2='' AND p.key1=? AND p.value1=? AND ((p.key2 LIKE '%' || ? || '%') OR (p.value2 LIKE '%' || ? || '%')) AND p.count_#{filter_type} > 0", key, value, params[:query], params[:query], key, value, params[:query], params[:query], key, value, params[:query], params[:query], key, value, params[:query], params[:query]) :
            @db.select("SELECT p.key1 AS other_key, p.value1 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.selected_tags k WHERE p.key1=k.skey AND p.value1=k.svalue AND k.svalue != '' AND p.key2=? AND p.value2=? AND p.count_#{filter_type} > 0 
                    UNION SELECT p.key1 AS other_key, '' AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.keys k WHERE p.key1=k.key AND p.value1 = '' AND p.key2=? AND p.value2=? AND p.count_#{filter_type} > 0 
                    UNION SELECT p.key2 AS other_key, p.value2 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.selected_tags k WHERE p.key2=k.skey AND p.value2=k.svalue AND k.svalue != '' AND p.key1=? AND p.value1=? AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, '' AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.keys k WHERE p.key2=k.key AND p.value2 = '' AND p.key1=? AND p.value1=? AND p.count_#{filter_type} > 0", key, value, key, value, key, value, key, value)).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.together_count
                o.other_key
                o.other_value
                o.from_fraction
            }.
            paging(@ap).
            execute()

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map{ |row| {
                :other_key      => row['other_key'],
                :other_value    => row['other_value'],
                :together_count => row['together_count'].to_i,
                :to_fraction    => (row['together_count'].to_f / has_this_key.to_f).round_to(4),
                :from_fraction  => row['from_fraction'].to_f.round_to(4)
            } }
        }.to_json
    end

end
