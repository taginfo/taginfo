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
        query_substr = like_contains(params[:query])

        if @ap.sortname == 'to_count'
            @ap.sortname = ['together_count']
        elsif @ap.sortname == 'from_count'
            @ap.sortname = ['from_fraction', 'together_count', 'other_key', 'other_value']
        elsif @ap.sortname == 'other_tag'
            @ap.sortname = ['other_key', 'other_value']
        end

        cq = @db.count('db.tag_combinations')
        total = (params[:query].to_s != '' ?
                cq.condition("(key1=? AND value1=? AND (key2 LIKE ? ESCAPE '@' OR value2 LIKE ? ESCAPE '@')) OR (key2=? AND value2=? AND (key1 LIKE ? ESCAPE '@' OR value2 LIKE ? ESCAPE '@'))",
                                    key,         value,           query_substr,               query_substr,           key,         value,           query_substr,               query_substr) :
                cq.condition('(key1=? AND value1=?) OR (key2=? AND value2=?)', key, value, key, value)).
            condition("count_#{filter_type} > 0").
            get_first_i

        has_this_key = @db.select("SELECT count_#{filter_type} FROM db.tags").
            condition('key = ?', key).
            condition('value = ?', value).
            get_first_value()

        res = (params[:query].to_s != '' ?
            @db.select("SELECT p.key1 AS other_key, p.value1 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, top_tags k WHERE p.key1=k.skey AND p.value1=k.svalue AND k.svalue != '' AND p.key2=? AND p.value2=? AND ((p.key1 LIKE ? ESCAPE '@') OR (p.value1 LIKE ? ESCAPE '@')) AND p.count_#{filter_type} > 0
                    UNION SELECT p.key1 AS other_key, p.value1 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.keys k WHERE p.key1=k.key AND p.value1='' AND p.key2=? AND p.value2=? AND ((p.key1 LIKE ? ESCAPE '@') OR (p.value1 LIKE ? ESCAPE '@')) AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, p.value2 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, top_tags k WHERE p.key2=k.skey AND p.value2=k.svalue AND k.svalue != '' AND p.key1=? AND p.value1=? AND ((p.key2 LIKE ? ESCAPE '@') OR (p.value2 LIKE ? ESCAPE '@')) AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, p.value2 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.keys k WHERE p.key2=k.key AND p.value2='' AND p.key1=? AND p.value1=? AND ((p.key2 LIKE ? ESCAPE '@') OR (p.value2 LIKE ? ESCAPE '@')) AND p.count_#{filter_type} > 0", key, value, query_substr, query_substr, key, value, query_substr, query_substr, key, value, query_substr, query_substr, key, value, query_substr, query_substr) :
            @db.select("SELECT p.key1 AS other_key, p.value1 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, top_tags k WHERE p.key1=k.skey AND p.value1=k.svalue AND k.svalue != '' AND p.key2=? AND p.value2=? AND p.count_#{filter_type} > 0
                    UNION SELECT p.key1 AS other_key, '' AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.keys k WHERE p.key1=k.key AND p.value1 = '' AND p.key2=? AND p.value2=? AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, p.value2 AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, top_tags k WHERE p.key2=k.skey AND p.value2=k.svalue AND k.svalue != '' AND p.key1=? AND p.value1=? AND p.count_#{filter_type} > 0
                    UNION SELECT p.key2 AS other_key, '' AS other_value, p.count_#{filter_type} AS together_count, k.count_#{filter_type} AS other_count, CAST(p.count_#{filter_type} AS REAL) / k.count_#{filter_type} AS from_fraction FROM db.tag_combinations p, db.keys k WHERE p.key2=k.key AND p.value2 = '' AND p.key1=? AND p.value1=? AND p.count_#{filter_type} > 0", key, value, key, value, key, value, key, value)).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.together_count
                o.other_key
                o.other_value
                o.from_fraction
            }.
            paging(@ap).
            execute()

        return generate_json_result(total,
            res.map{ |row| {
                :other_key      => row['other_key'],
                :other_value    => row['other_value'],
                :together_count => row['together_count'].to_i,
                :to_fraction    => (row['together_count'].to_f / has_this_key.to_f).round(4),
                :from_fraction  => row['from_fraction'].to_f.round(4)
            } }
        )
    end

    api(4, 'tag/distribution/nodes', {
        :description => 'Get map with distribution of this tag in the database (nodes only). Will return empty image if there is no map available for this tag.',
        :parameters => { :key => 'Tag key (required).', :value => 'Tag value (required).' },
        :result => 'PNG image.',
        :example => { :key => 'amenity', :value => 'post_box' },
        :ui => '/tags/amenity=post_box#map'
    }) do
        get_png('tag', 'n', params[:key], params[:value])
    end

    api(4, 'tag/distribution/ways', {
        :description => 'Get map with distribution of this tag in the database (ways only). Will return empty image if there is no map available for this tag.',
        :parameters => { :key => 'Tag key (required).', :value => 'Tag value (required).' },
        :result => 'PNG image.',
        :example => { :key => 'highway', :value => 'residential' },
        :ui => '/tags/highway=residential#map'
    }) do
        get_png('tag', 'w', params[:key], params[:value])
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
            condition('key = ? AND value = ?', key, value).
            execute() do |row|
                ['all', 'nodes', 'ways', 'relations'].each_with_index do |type, n|
                    out[n] = {
                        :type           => type,
                        :count          => row['count_'  + type].to_i,
                        :count_fraction => (row['count_'  + type].to_f / get_total(type)).round(4)
                    }
                end
        end

        return generate_json_result(4, out);
    end

    api(4, 'tag/wiki_pages', {
        :description => 'Get list of wiki pages in different languages describing a tag.',
        :parameters => { :key => 'Tag key (required)', :value => 'Tag value (required).' },
        :paging => :no,
        :result => no_paging_results([
            [:lang,             :STRING, 'Language code.'],
            [:dir,              :STRING, 'Writing direction ("ltr", "rtl", or "auto") of description.'],
            [:language,         :STRING, 'Language name in its language.'],
            [:language_en,      :STRING, 'Language name in English.'],
            [:title,            :STRING, 'Wiki page title.'],
            [:description,      :STRING, 'Short description of tag from wiki page.'],
            [:image,            :HASH,   'Associated image.', [
                [:title,            :STRING, 'Wiki page title of associated image.' ],
                [:width,            :INT,    'Width of image.' ],
                [:height,           :INT,    'Height of image.' ],
                [:mime,             :STRING, 'MIME type of image.' ],
                [:image_url,        :STRING, 'Image URL' ],
                [:thumb_url_prefix, :STRING, 'Prefix of thumbnail URL.' ],
                [:thumb_url_suffix, :STRING, 'Suffix of thumbnail URL.' ]
            ]],
            [:on_node,          :BOOL,   'Is this a tag for nodes?'],
            [:on_way,           :BOOL,   'Is this a tag for ways?'],
            [:on_area,          :BOOL,   'Is this a tag for areas?'],
            [:on_relation,      :BOOL,   'Is this a tag for relations?'],
            [:tags_implies,     :ARRAY_OF_STRINGS, 'List of keys/tags implied by this tag.'],
            [:tags_combination, :ARRAY_OF_STRINGS, 'List of keys/tags that can be combined with this tag.'],
            [:tags_linked,      :ARRAY_OF_STRINGS, 'List of keys/tags related to this tag.'],
            [:status,           :STRING, 'Status of this key/tag.']
        ]),
        :notes => 'To get the complete thumbnail image URL, concatenate <tt>thumb_url_prefix</tt>, width of image in pixels, and <tt>thumb_url_suffix</tt>. The thumbnail image width must be smaller than <tt>width</tt>, use the <tt>image_url</tt> otherwise.',
        :example => { :key => 'highway', :value => 'residential' },
        :ui => '/tags/highway=residential#wiki'
    }) do
        key   = params[:key]
        value = params[:value]

        res = @db.execute('SELECT * FROM wiki.wikipages LEFT OUTER JOIN wiki_images USING (image) WHERE key = ? AND value = ? ORDER BY lang', key, value)

        return get_wiki_result(res)
    end

    api(4, 'tag/projects', {
        :description => 'Get projects using a given tag.',
        :parameters => {
            :key => 'Tag key (required).',
            :value => 'Tag value (required).',
            :query => 'Only show results where the project name matches this query (substring match, optional).'
        },
        :paging => :optional,
        :filter => {
            :all       => { :doc => 'No filter.' },
            :nodes     => { :doc => 'Only values on tags used on nodes.' },
            :ways      => { :doc => 'Only values on tags used on ways.' },
            :relations => { :doc => 'Only values on tags used on relations.' }
        },
        :sort => %w( project_name tag ),
        :result => paging_results([
            [:project_id,       :STRING, 'Project ID'],
            [:project_name,     :STRING, 'Project name'],
            [:project_icon_url, :STRING, 'Project icon URL'],
            [:key,              :STRING, 'Key'],
            [:value,            :STRING, 'Value'],
            [:on_node,          :BOOL,   'For nodes?'],
            [:on_way,           :BOOL,   'For ways?'],
            [:on_relation,      :BOOL,   'For relations?'],
            [:on_area,          :BOOL,   'For areas?'],
            [:description,      :STRING, 'Description'],
            [:doc_url,          :STRING, 'Documentation URL'],
            [:icon_url,         :STRING, 'Icon URL']
        ]),
        :example => { :key => 'highway', :value => 'residential', :page => 1, :rp => 10, :sortname => 'project_name', :sortorder => 'asc' },
        :ui => '/tags/highway=residential#projects'
    }) do
        key = params[:key]
        value = params[:value]
        filter_type = get_filter()
        q = like_contains(params[:query])

        total = @db.select("SELECT count(*) FROM (SELECT project_id, key, MAX(value) AS value FROM projects.project_tags WHERE key=? AND (value=? OR value IS NULL) GROUP BY project_id, key) AS s JOIN projects.project_tags t JOIN projects.projects p ON p.id=t.project_id AND t.project_id=s.project_id AND t.key=s.key AND (t.value=s.value OR (t.value IS NULL AND s.value IS NULL))", key, value).
            condition("p.status = 'OK'").
            condition_if("name LIKE ? ESCAPE '@'", q).
            condition_if("on_node = ?",                    filter_type == 'nodes'     ? 1 : '').
            condition_if("on_way = ? OR on_area = 1",      filter_type == 'ways'      ? 1 : '').
            condition_if("on_relation = ? OR on_area = 1", filter_type == 'relations' ? 1 : '').
            get_first_value().to_i

        res = @db.select("SELECT p.name, p.icon_url AS project_icon_url, t.* FROM (SELECT project_id, key, MAX(value) AS value FROM projects.project_tags WHERE key=? AND (value=? OR value IS NULL) GROUP BY project_id, key) AS s JOIN projects.project_tags t JOIN projects.projects p ON p.id=t.project_id AND t.project_id=s.project_id AND t.key=s.key AND (t.value=s.value OR (t.value IS NULL AND s.value IS NULL))", key, value).
            condition("p.status = 'OK'").
            condition_if("name LIKE ? ESCAPE '@'", q).
            condition_if("on_node = ?",                    filter_type == 'nodes'     ? 1 : '').
            condition_if("on_way = ? OR on_area = 1",      filter_type == 'ways'      ? 1 : '').
            condition_if("on_relation = ? OR on_area = 1", filter_type == 'relations' ? 1 : '').
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.project_name 'lower(p.name)'
                o.project_name :value
                o.tag! :value
                o.tag 'lower(p.name)'
            }.
            paging(@ap).
            execute()

        return generate_json_result(total,
            res.map{ |row| {
                :project_id       => row['project_id'],
                :project_name     => row['name'],
                :project_icon_url => row['project_icon_url'],
                :key              => row['key'],
                :value            => row['value'],
                :on_node          => row['on_node'].to_i     == 1,
                :on_way           => row['on_way'].to_i      == 1,
                :on_relation      => row['on_relation'].to_i == 1,
                :on_area          => row['on_area'].to_i     == 1,
                :description      => row['description'],
                :doc_url          => row['doc_url'],
                :icon_url         => row['icon_url']
            } }
        )
    end

    api(4, 'tag/chronology', {
        :description => 'Get chronology of tag counts.',
        :parameters => {
            :key => 'Tag key (required).',
            :value => 'Tag value (required).',
        },
        :paging => :no,
        :result => no_paging_results([
            [:date,      :TEXT, 'Date in format YYYY-MM-DD.'],
            [:nodes,     :INT, 'Difference of number of nodes with this tag relative to previous entry.'],
            [:ways,      :INT, 'Difference of number of ways with this tag relative to previous entry.'],
            [:relations, :INT, 'Difference of number of relations with this tag relative to previous entry.']
        ]),
        :example => { :key => 'highway', :value => 'primary' },
        :ui => '/tags/highway=primary#chronology'
    }) do
        if not Source.get(:chronology)
            return generate_json_result(0, []);
        end

        key = params[:key]
        value = params[:value]

        res = @db.select('SELECT data FROM chronology.tags_chronology').
            condition('key = ?', key).
            condition('value = ?', value).
            get_first_value()

        data = unpack_chronology(res)

        return generate_json_result(data.size(), data);
    end

    api(4, 'tag/overview', {
        :description => 'Show various data for given tag.',
        :parameters => {
            :key => 'Tag key (required).',
            :value => 'Tag value (required).'
        },
        :result => [
            [ :total,      :INT, 'Total number of results (always 1).' ],
            [ :url,        :STRING, 'URL of the request.' ],
            [ :data_until, :STRING, 'All changes in the source until this date are reflected in this taginfo result.' ],
            [ :data,       :HASH, 'Hash with data.', [
                [:key,              :STRING, 'The tag key that was requested.'],
                [:value,            :STRING, 'The tag value that was requested.'],
                [:projects,         :INT, 'Number of projects mentioning this tag.'],
                [:wiki_pages,       :ARRAY_OF_HASHES, 'Language codes for which wiki pages about this tag are available.', [
                    [:lang,    :STRING, 'Language code.'],
                    [:english, :STRING, 'English name of this language.'],
                    [:native,  :STRING, 'Native name of this language.'],
                    [:dir,     :STRING, 'Printing direction for native name ("ltr", "rtl", or "auto")'],
                ]],
                [:has_map,          :BOOL, 'Is a map with the geographical distribution of this tag available?'],
                [:counts,           :ARRAY_OF_HASHES, 'Objects counts.', [
                    [:type,           :STRING, 'Object type ("all", "nodes", "ways", or "relations")'],
                    [:count,          :INT,    'Number of objects with this type and tag.'],
                    [:count_fraction, :FLOAT,  'Number of objects in relation to all objects.']
                ]],
                [:description,      :HASH_OF_HASHES, 'Description of this tag (hash key is language code).', [
                    [:text, :STRING, 'Description text.' ],
                    [:dir,  :STRING, 'Printing direction for this language ("ltr", "rtl", or "auto").' ]
                ]],
            ]]
        ],
        :example => { :key => 'amenity', :value => 'restaurant' },
        :ui => '/tags/amenity=restaurant#overview'
    }) do
        key = params[:key]
        value = params[:value]
        data = { :key => key, :value => value, :counts => [] }

        # default values
        ['all', 'nodes', 'ways', 'relations'].each_with_index do |type, n|
            data[:counts][n] = { :type => type, :count => 0, :count_fraction => 0.0 }
        end

        row = @db.select("SELECT count_all, count_nodes, count_ways, count_relations FROM db.tags").condition('key=? AND value=?', key, value).get_first_row()
        if row
            ['all', 'nodes', 'ways', 'relations'].each_with_index do |type, n|
                data[:counts][n] = {
                    :type           => type,
                    :count          => row['count_' + type].to_i,
                    :count_fraction => (row['count_' + type].to_f / get_total(type)).round(4)
                }
            end
        end

        data[:wiki_pages] = @db.select("SELECT DISTINCT lang FROM wiki.wikipages WHERE key=? AND value=? ORDER BY lang", key, value).execute().map do |row|
            lang = row['lang']
            {
                :lang    => lang,
                :english => ::Language[lang].english_name,
                :native  => ::Language[lang].native_name,
                :dir     => direction_from_lang_code(lang)
            }
        end

        data[:projects] = @db.select("SELECT projects FROM projects.project_unique_tags WHERE key=? AND value=?", key, value).execute().map{ |row| row['projects'] }[0] || 0

        data[:has_map] = (@db.count('tag_distributions').condition('key=? AND value=?', key, value).get_first_i > 0)

        data[:description] = {}
        @db.select("SELECT description, lang FROM wiki.wikipages WHERE key=? AND value=? AND description IS NOT NULL ORDER BY lang", key, value).execute().each{ |row|
            data[:description][row['lang']] = { :text => row['description'], :dir => direction_from_lang_code(row['lang']) }
        }


        return generate_json_result(1, data);
    end
end
