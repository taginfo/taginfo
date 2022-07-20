# web/lib/api/v4/relation.rb
class Taginfo < Sinatra::Base

    api(4, 'relation/roles', {
        :description => 'Member role statistics for a relation of given type.',
        :parameters => {
            :rtype => 'Relation type (required).',
            :query => 'Only show results where the role matches this query (substring match, optional).',
            :min_fraction => 'Only return roles which are used in at least this percent of all members (optional).'
        },
        :paging => :optional,
        :sort => %w( role count_all_members count_node_members count_way_members count_relation_members ),
        :result => paging_results([
            [:rtype,                           :STRING, 'Relation type'],
            [:role,                            :STRING, 'Relation member role.'],
            [:count_all_members,               :INT,    'Number of members with this role.'],
            [:count_all_members_fraction,      :FLOAT,  'Number of members with this role devided by all members.'],
            [:count_node_members,              :INT,    'Number of members of type node with this role.'],
            [:count_node_members_fraction,     :FLOAT,  'Number of members of type node with this role devided by all members of type node.'],
            [:count_way_members,               :INT,    'Number of members of type way with this role.'],
            [:count_way_members_fraction,      :FLOAT,  'Number of members of type way with this role devided by all members of type way.'],
            [:count_relation_members,          :INT,    'Number of members of type relation with this role.'],
            [:count_relation_members_fraction, :FLOAT,  'Number of members of type relation with this role devided by all members of type relation.']
        ]),
        :example => { :rtype => 'multipolygon', :page => 1, :rp => 10 },
        :ui => '/relations/multipolygon#roles',
        :notes => 'If the <i>query</i> parameter is not set and the <i>min_fraction</i> parameter is set and paging is disabled, the first row returned will have the role <i>null</i> and the counts are added up from all the results not shown due to the <i>min_fraction</i> parameter.'
    }) do
        rtype = params[:rtype]

        relation_type_info = @db.select('SELECT * FROM relation_types').
            condition("rtype=?", rtype).
            execute()[0]

        if params[:min_fraction]
            min_count = params[:min_fraction].to_f * relation_type_info['members_all'].to_f
        end

        total = @db.count('relation_roles').
            condition("rtype=?", rtype).
            condition_if("role LIKE ? ESCAPE '@'", like_contains(params[:query])).
            condition_if("count_all >= ?", min_count).
            get_first_i

        res = @db.select('SELECT * FROM relation_roles').
            condition("rtype=?", rtype).
            condition_if("role LIKE ? ESCAPE '@'", like_contains(params[:query])).
            condition_if("count_all >= ?", min_count).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.role
                o.count_all_members      :count_all
                o.count_node_members     :count_nodes
                o.count_way_members      :count_ways
                o.count_relation_members :count_relations
            }.
            paging(@ap).
            execute()

        if min_count and not params[:query] and not @ap.do_paging?
            row = @db.execute('SELECT rtype, NULL AS role, sum(count_all) AS count_all, sum(count_nodes) AS count_nodes, sum(count_ways) AS count_ways, sum(count_relations) AS relations FROM relation_roles WHERE rtype=? AND count_all < ? GROUP BY rtype', rtype, min_count).first
            if row and row['count_all'].to_i > 0
                res.unshift(row)
                total += 1
            end
        end

        return generate_json_result(total,
            res.map{ |row| {
                :rtype                           =>  row['rtype'],
                :role                            =>  row['role'],
                :count_all_members               =>  row['count_all'].to_i,
                :count_all_members_fraction      => (row['count_all'].to_f / relation_type_info['members_all'].to_i).round(4),
                :count_node_members              =>  row['count_nodes'].to_i,
                :count_node_members_fraction     =>  relation_type_info['members_nodes'].to_i == 0 ? 0 : (row['count_nodes'].to_f / relation_type_info['members_nodes'].to_i).round(4),
                :count_way_members               =>  row['count_ways'].to_i,
                :count_way_members_fraction      =>  relation_type_info['members_ways'].to_i == 0 ? 0 : (row['count_ways'].to_f / relation_type_info['members_ways'].to_i).round(4),
                :count_relation_members          =>  row['count_relations'].to_i,
                :count_relation_members_fraction =>  relation_type_info['members_relations'].to_i == 0 ? 0 : (row['count_relations'].to_f / relation_type_info['members_relations'].to_i).round(4),
            } }
        )
    end

    api(4, 'relation/stats', {
        :description => 'Show some database statistics for given relation type.',
        :parameters => { :rtype => 'Relation type (required).' },
        :result => no_paging_results([
            [:type,  :STRING, 'Member type ("all", "nodes", "ways", or "relations")'],
            [:count, :INT,    'Number of members with this type.']
        ]),
        :example => { :rtype => 'multipolygon' },
        :ui => '/relations/multipolygon#overview'
    }) do
        rtype = params[:rtype]
        out = []

        # default values
        ['all', 'nodes', 'ways', 'relations'].each_with_index do |type, n|
            out[n] = { :type => type, :count => 0 }
        end

        @db.select('SELECT * FROM db.relation_types').
            condition('rtype = ?', rtype).
            execute() do |row|
                ['all', 'nodes', 'ways', 'relations'].each_with_index do |type, n|
                    out[n] = {
                        :type   => type,
                        :count  => row['members_' + type].to_i
                    }
                end
            end

        return generate_json_result(4, out);
    end

    api(4, 'relation/wiki_pages', {
        :description => 'Get list of wiki pages in different languages describing a relation type.',
        :parameters => { :rtype => 'Relation type (required)' },
        :paging => :no,
        :result => no_paging_results([
            [:lang,             :STRING, 'Language code.'],
            [:language,         :STRING, 'Language name in its language.'],
            [:language_en,      :STRING, 'Language name in English.'],
            [:title,            :STRING, 'Wiki page title.'],
            [:dir,              :STRING, 'Writing direction ("ltr", "rtl", or "auto") of description.'],
            [:description,      :STRING, 'Short description of key from wiki page.'],
            [:image,            :HASH,   'Associated image.', [
                [:title,            :STRING, 'Wiki page title of associated image.' ],
                [:width,            :INT,    'Width of image.' ],
                [:height,           :INT,    'Height of image.' ],
                [:mime,             :STRING, 'MIME type of image.' ],
                [:image_url,        :STRING, 'Image URL' ],
                [:thumb_url_prefix, :STRING, 'Prefix of thumbnail URL.' ],
                [:thumb_url_suffix, :STRING, 'Suffix of thumbnail URL.' ]
            ]]
        ]),
        :notes => 'To get the complete thumbnail image URL, concatenate <tt>thumb_url_prefix</tt>, width of image in pixels, and <tt>thumb_url_suffix</tt>. The thumbnail image width must be smaller than <tt>width</tt>, use the <tt>image_url</tt> otherwise.',
        :example => { :rtype => 'multipolygon' },
        :ui => '/relations/multipolygon#wiki'
    }) do
        rtype = params[:rtype]

        res = @db.execute('SELECT * FROM wiki.relation_pages LEFT OUTER JOIN wiki.wiki_images USING (image) WHERE rtype = ? ORDER BY lang', rtype)

        return generate_json_result(res.size, res.map{ |row|
                {
                :lang             => row['lang'],
                :dir              => direction_from_lang_code(row['lang']),
                :language         => ::Language[row['lang']].native_name,
                :language_en      => ::Language[row['lang']].english_name,
                :title            => row['title'],
                :description      => row['description'],
                :image            => {
                    :title            => row['image'],
                    :width            => row['width'].to_i,
                    :height           => row['height'].to_i,
                    :mime             => row['mime'],
                    :image_url        => row['image_url'],
                    :thumb_url_prefix => row['thumb_url_prefix'],
                    :thumb_url_suffix => row['thumb_url_suffix']
                }
            }
        })
    end

    api(4, 'relation/projects', {
        :description => 'Get projects using a given relation type.',
        :parameters => {
            :rtype => 'Relation type (required)',
            :query => 'Only show results where the value matches this query (substring match, optional).'
        },
        :paging => :optional,
        :sort => %w( project_name ),
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
        :example => { :rtype => 'route', :page => 1, :rp => 10, :sortname => 'project_name', :sortorder => 'asc' },
        :ui => '/relations/route#projects'
    }) do
        rtype = params[:rtype]
        q = like_contains(params[:query])

        total = @db.select('SELECT count(*) FROM projects.projects p, projects.project_tags t ON p.id=t.project_id').
            condition("status = 'OK' AND on_relation = 1").
            condition("key = 'type' AND value = ?", rtype).
            condition_if("value LIKE ? ESCAPE '@' OR name LIKE ? ESCAPE '@'", q, q).
            get_first_i

        res = @db.select('SELECT t.project_id, p.name, p.icon_url AS project_icon_url, t.value, t.description, t.doc_url, t.icon_url FROM projects.projects p, projects.project_tags t ON p.id=t.project_id').
            condition("status = 'OK' AND on_relation = 1").
            condition("key = 'type' AND value = ?", rtype).
            condition_if("value LIKE ? ESCAPE '@' OR name LIKE ? ESCAPE '@'", q, q).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.project_name 'lower(p.name)'
            }.
            paging(@ap).
            execute()

        return generate_json_result(total,
            res.map{ |row| {
                :project_id       => row['project_id'],
                :project_name     => row['name'],
                :project_icon_url => row['project_icon_url'],
                :rtype            => row['value'],
                :description      => row['description'],
                :doc_url          => row['doc_url'],
                :icon_url         => row['icon_url']
            } }
        )
    end

end
