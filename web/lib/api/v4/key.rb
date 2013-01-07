# web/lib/api/v4/key.rb
class Taginfo < Sinatra::Base

    api(4, 'key/combinations', {
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
        :result => paging_results([
            [:other_key,      :STRING, 'Other key.'],
            [:together_count, :INT,    'Number of objects that have both keys.'],
            [:to_fraction,    :FLOAT,  'Fraction of objects with this key that also have the other key.'],
            [:from_fraction,  :FLOAT,  'Fraction of objects with other key that also have this key.']
        ]),
        :example => { :key => 'highway', :page => 1, :rp => 10, :sortname => 'together_count', :sortorder => 'desc' },
        :ui => '/keys/highway#combinations'
    }) do
        key = params[:key]
        filter_type = get_filter()

        if @ap.sortname == 'to_count'
            @ap.sortname = ['together_count']
        elsif @ap.sortname == 'from_count'
            @ap.sortname = ['from_fraction', 'together_count', 'other_key']
        end

        cq = @db.count('db.keypairs')
        total = (params[:query].to_s != '' ? cq.condition("(key1 = ? AND key2 LIKE '%' || ? || '%') OR (key2 = ? AND key1 LIKE '%' || ? || '%')", key, params[:query], key, params[:query]) : cq.condition('key1 = ? OR key2 = ?', key, key)).
            condition("count_#{filter_type} > 0").
            get_first_value().to_i

        has_this_key = @db.select("SELECT count_#{filter_type} FROM db.keys").
            condition('key = ?', key).
            get_first_value()

        res = (params[:query].to_s != '' ?
            @db.select("SELECT p.key1 AS other_key, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.keypairs p, db.keys k WHERE p.key1=k.key AND p.key2=? AND (p.key1 LIKE '%' || ? || '%') AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.keypairs p, db.keys k WHERE p.key2=k.key AND p.key1=? AND (p.key2 LIKE '%' || ? || '%') AND p.count_#{filter_type} > 0", key, params[:query], key, params[:query]) :
            @db.select("SELECT p.key1 AS other_key, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.keypairs p, db.keys k WHERE p.key1=k.key AND p.key2=? AND p.count_#{filter_type} > 0 
                    UNION SELECT p.key2 AS other_key, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.keypairs p, db.keys k WHERE p.key2=k.key AND p.key1=? AND p.count_#{filter_type} > 0", key, key)).
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

    api(4, 'key/distribution/nodes', {
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

    api(4, 'key/distribution/ways', {
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

    api(4, 'key/josm/style/rules', {
        :description => 'List rules and symbols for the given key in JOSM styles.',
        :parameters => {
            :style => 'JOSM style (required).',
            :key   => 'Tag key (required).',
            :query => 'Only show results where the value matches this query (substring match, optional).'
        },
        :paging => :optional,
        :result => paging_results([
            [:key,        :STRING, 'Key'],
            [:value,      :STRING, 'Value'],
            [:value_bool, :STRING, '"yes" or "no". Null if the value is not boolean.'],
            [:rule,       :STRING, 'JOSM style rule in XML format.'],
            [:area_color, :STRING, 'Fill color for area (if area rule).'],
            [:line_color, :STRING, 'Stroke color for line (if line rule).'],
            [:line_width, :INT,    'Line width (if line rule).'],
            [:icon,       :STRING, 'Icon path (if icon rule).']
        ]),
        :example => { :style => 'standard', :key => 'highway', :page => 1, :rp => 10},
        :ui => '/keys/highway#josm'
    }) do
        style = params[:style]
        key   = params[:key]
        
        total = @db.count('josm_style_rules').
#            condition('style = ?', style).
            condition('k = ?', key).
            condition_if("v LIKE '%' || ? || '%'", params[:query]).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
#            condition('style = ?', style).
            condition('k = ?', key).
            condition_if("v LIKE '%' || ? || '%'", params[:query]).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.value :v
                o.value :b
                o.b
            }.
            paging(@ap).
            execute()

        return get_josm_style_rules_result(total, res);
    end

    api(4, 'key/stats', {
        :description => 'Show some database statistics for given key.',
        :parameters => { :key => 'Tag key (required).' },
        :result => no_paging_results([
            [:type,           :STRING, 'Object type ("all", "nodes", "ways", or "relations")'],
            [:count,          :INT,    'Number of objects with this type and key.'],
            [:count_fraction, :FLOAT,  'Number of objects in relation to all objects.'],
            [:values,         :INT,    'Number of different values for this key.']
        ]),
        :example => { :key => 'amenity' },
        :ui => '/keys/amenity#overview'
    }) do
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

        return {
            :total => 4,
            :data => out
        }.to_json
    end

    api(4, 'key/values', {
        :description => 'Get values used with a given key.',
        :parameters => {
            :key => 'Tag key (required).',
            :lang => "Language for description (optional, default: 'en').",
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
        :result => paging_results([
            [:value,       :STRING, 'Value'],
            [:count,       :INT,    'Number of times this key/value is in the OSM database.'],
            [:fraction,    :FLOAT,  'Number of times in relation to number of times this key is in the OSM database.'],
            [:description, :STRING, 'Description of the tag from the wiki.']
        ]),
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

    api(4, 'key/wiki_pages', {
        :description => 'Get list of wiki pages in different languages describing a key.',
        :parameters => { :key => 'Tag key (required)' },
        :paging => :no,
        :result => no_paging_results([
            [:lang,             :STRING, 'Language code.'],
            [:language,         :STRING, 'Language name in its language.'],
            [:language_en,      :STRING, 'Language name in English.'],
            [:title,            :STRING, 'Wiki page title.'],
            [:description,      :STRING, 'Short description of key from wiki page.'],
            [:image,            :STRING, 'Wiki page title of associated image.'],
            [:on_node,          :BOOL,   'Is this a key for nodes?'],
            [:on_way,           :BOOL,   'Is this a key for ways?'],
            [:on_area,          :BOOL,   'Is this a key for areas?'],
            [:on_relation,      :BOOL,   'Is this a key for relations?'],
            [:tags_implies,     :ARRAY_OF_STRINGS, 'List of keys/tags implied by this key.'],
            [:tags_combination, :ARRAY_OF_STRINGS, 'List of keys/tags that can be combined with this key.'],
            [:tags_linked,      :ARRAY_OF_STRINGS, 'List of keys/tags related to this key.']
        ]),
        :example => { :key => 'highway' },
        :ui => '/keys/highway#wiki'
    }) do
        key = params[:key]

        res = @db.execute('SELECT * FROM wikipages WHERE value IS NULL AND key = ? ORDER BY lang', key)

        return get_wiki_result(res)
    end

end
