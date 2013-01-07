# web/lib/api/v4/tag.rb
class Taginfo < Sinatra::Base

    api(4, 'tag/combinations', {
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
        :result => paging_results([
            [:other_key,      :STRING, 'Other key.'],
            [:other_value,    :STRING, 'Other value (may be empty).'],
            [:together_count, :INT,    'Number of objects that have both this tag and other key (or tag).'],
            [:to_fraction,    :FLOAT,  'Fraction of objects with this tag that also have the other key (or tag).'],
            [:from_fraction,  :FLOAT,  'Fraction of objects with other key (or tag) that also have this tag.']
        ]),
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

        cq = @db.count('db.tagpairs')
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
            @db.select("SELECT p.key1 AS other_key, p.value1 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tagpairs p, db.selected_tags k WHERE p.key1=k.skey AND p.value1=k.svalue AND k.svalue != '' AND p.key2=? AND p.value2=? AND ((p.key1 LIKE '%' || ? || '%') OR (p.value1 LIKE '%' || ? || '%')) AND p.count_#{filter_type} > 0
                    UNION SELECT p.key1 AS other_key, p.value1 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tagpairs p, db.keys k WHERE p.key1=k.key AND p.value1='' AND p.key2=? AND p.value2=? AND ((p.key1 LIKE '%' || ? || '%') OR (p.value1 LIKE '%' || ? || '%')) AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, p.value2 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tagpairs p, db.selected_tags k WHERE p.key2=k.skey AND p.value2=k.svalue AND k.svalue != '' AND p.key1=? AND p.value1=? AND ((p.key2 LIKE '%' || ? || '%') OR (p.value2 LIKE '%' || ? || '%')) AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, p.value2 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tagpairs p, db.keys k WHERE p.key2=k.key AND p.value2='' AND p.key1=? AND p.value1=? AND ((p.key2 LIKE '%' || ? || '%') OR (p.value2 LIKE '%' || ? || '%')) AND p.count_#{filter_type} > 0", key, value, params[:query], params[:query], key, value, params[:query], params[:query], key, value, params[:query], params[:query], key, value, params[:query], params[:query]) :
            @db.select("SELECT p.key1 AS other_key, p.value1 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tagpairs p, db.selected_tags k WHERE p.key1=k.skey AND p.value1=k.svalue AND k.svalue != '' AND p.key2=? AND p.value2=? AND p.count_#{filter_type} > 0 
                    UNION SELECT p.key1 AS other_key, '' AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tagpairs p, db.keys k WHERE p.key1=k.key AND p.value1 = '' AND p.key2=? AND p.value2=? AND p.count_#{filter_type} > 0 
                    UNION SELECT p.key2 AS other_key, p.value2 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tagpairs p, db.selected_tags k WHERE p.key2=k.skey AND p.value2=k.svalue AND k.svalue != '' AND p.key1=? AND p.value1=? AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, '' AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tagpairs p, db.keys k WHERE p.key2=k.key AND p.value2 = '' AND p.key1=? AND p.value1=? AND p.count_#{filter_type} > 0", key, value, key, value, key, value, key, value)).
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

    api(4, 'tag/josm/style/rules', {
        :description => 'List rules and symbols for the given tag in JOSM styles.',
        :parameters => {
            :style => 'JOSM style (required).',
            :key   => 'Tag key (required).',
            :value => 'Tag value (required).'
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
        :example => { :style => 'standard', :key => 'highway', :value => 'residential', :page => 1, :rp => 10 },
        :ui => '/tags/highway=residential#josm'
    }) do
        style = params[:style]
        key   = params[:key]
        value = params[:value]

        total = @db.count('josm_style_rules').
#            condition('style = ?', style).
            condition('k = ?', key).
            condition('v = ?', value).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
#            condition('style = ?', style).
            condition('k = ?', key).
            condition('v = ?', value).
            order_by([:k, :v], 'ASC').
            paging(@ap).
            execute()

        return get_josm_style_rules_result(total, res);
    end

    api(4, 'tag/stats', {
        :description => 'Show some database statistics for given tag.',
        :parameters => {
            :key => 'Tag key (required).',
            :value => 'Tag value (required).'
        },
        :result => no_paging_results([
            [:type,           :STRING, 'Object type ("all", "nodes", "ways", or "relations")'],
            [:count,          :INT,    'Number of objects with this type and tag.'],
            [:count_fraction, :FLOAT,  'Number of objects in relation to all objects.']
        ]),
        :example => { :key => 'amenity', :value => 'school' },
        :ui => '/tags/amenity=school#overview'
    }) do
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

        return {
            :total => 4,
            :data => out
        }.to_json
    end

    api(4, 'tag/wiki_pages', {
        :description => 'Get list of wiki pages in different languages describing a tag.',
        :parameters => { :key => 'Tag key (required)', :value => 'Tag value (required).' },
        :paging => :no,
        :result => no_paging_results([
            [:lang,             :STRING, 'Language code.'],
            [:language,         :STRING, 'Language name in its language.'],
            [:language_en,      :STRING, 'Language name in English.'],
            [:title,            :STRING, 'Wiki page title.'],
            [:description,      :STRING, 'Short description of tag from wiki page.'],
            [:image,            :STRING, 'Wiki page title of associated image.'],
            [:on_node,          :BOOL,   'Is this a tag for nodes?'],
            [:on_way,           :BOOL,   'Is this a tag for ways?'],
            [:on_area,          :BOOL,   'Is this a tag for areas?'],
            [:on_relation,      :BOOL,   'Is this a tag for relations?'],
            [:tags_implies,     :ARRAY_OF_STRINGS, 'List of keys/tags implied by this tag.'],
            [:tags_combination, :ARRAY_OF_STRINGS, 'List of keys/tags that can be combined with this tag.'],
            [:tags_linked,      :ARRAY_OF_STRINGS, 'List of keys/tags related to this tag.']
        ]),
        :example => { :key => 'highway', :value => 'residential' },
        :ui => '/tags/highway=residential#wiki'
    }) do
        key   = params[:key]
        value = params[:value]

        res = @db.execute('SELECT * FROM wikipages WHERE key = ? AND value = ? ORDER BY lang', key, value)

        return get_wiki_result(res)
    end

end
