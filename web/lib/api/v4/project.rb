# web/lib/api/v4/project.rb
class Taginfo < Sinatra::Base

    api(4, 'project/tags', {
        :description => 'Get list of all keys/tags used by a project.',
        :parameters => { :project => 'Project ID (required)' },
        :paging => :optional,
        :sort => %w[ tag count_all in_wiki ],
        :result => paging_results([
            [:key,         :STRING,  'Key'],
            [:value,       :STRING,  'Value'],
            [:on_node,     :BOOL,    'For nodes?'],
            [:on_way,      :BOOL,    'For ways?'],
            [:on_relation, :BOOL,    'For relations?'],
            [:on_area,     :BOOL,    'For areas?'],
            [:description, :STRING,  'Description'],
            [:doc_url,     :STRING,  'Documentation URL'],
            [:icon_url,    :STRING,  'Icon URL'],
            [:count_all,   :INTEGER, 'Number of objects with this key/tag in database'],
            [:in_wiki,     :BOOL,    'Is there at least one wiki page for this key/tag?']
        ]),
        :example => { :project => 'id_editor', :page => 1, :rp => 10, :sortname => 'tag', :sortorder => 'asc' },
        :ui => '/projects/id_editor'
    }) do
        project_id = params[:project]

        q = like_contains(params[:query])
        total = @db.select('SELECT count(*) FROM (SELECT p.key AS key, p.value AS value, p.on_node, p.on_way, p.on_relation, p.on_area, p.description, p.doc_url, p.icon_url, k.in_wiki, k.count_all FROM projects.project_tags p, projects.project_unique_keys k WHERE p.project_id=? AND p.key = k.key AND p.value IS NULL UNION SELECT p.key AS key, p.value AS value, p.on_node, p.on_way, p.on_relation, p.on_area, p.description, p.doc_url, p.icon_url, t.in_wiki, t.count_all FROM projects.project_tags p, projects.project_unique_tags t WHERE p.project_id=? AND p.key = t.key AND p.value = t.value)', project_id, project_id).
            condition_if("key LIKE ? ESCAPE '@' OR value LIKE ? ESCAPE '@'", q, q).
            get_first_i

        res = @db.select('SELECT * FROM (SELECT p.key AS key, p.value AS value, p.on_node, p.on_way, p.on_relation, p.on_area, p.description, p.doc_url, p.icon_url, k.in_wiki, k.count_all FROM projects.project_tags p, projects.project_unique_keys k WHERE p.project_id=? AND p.key = k.key AND p.value IS NULL UNION SELECT p.key AS key, p.value AS value, p.on_node, p.on_way, p.on_relation, p.on_area, p.description, p.doc_url, p.icon_url, t.in_wiki, t.count_all FROM projects.project_tags p, projects.project_unique_tags t WHERE p.project_id=? AND p.key = t.key AND p.value = t.value)', project_id, project_id).
            condition_if("key LIKE ? ESCAPE '@' OR value LIKE ? ESCAPE '@'", q, q).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.tag :key
                o.tag :value
                o.count_all
                o.in_wiki :in_wiki
                o.in_wiki :key
                o.in_wiki :value
            end.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                :key         => row['key'],
                :value       => row['value'],
                :on_node     => row['on_node'].to_i     == 1,
                :on_way      => row['on_way'].to_i      == 1,
                :on_relation => row['on_relation'].to_i == 1,
                :on_area     => row['on_area'].to_i     == 1,
                :description => row['description'],
                :doc_url     => row['doc_url'],
                :icon_url    => row['icon_url'],
                :count_all   => row['count_all'],
                :in_wiki     => row['in_wiki'].to_i != 0
            }
            end
        )
    end

    api(4, 'project/icon', {
        :description => 'Get icon of a project.',
        :parameters => { :project => 'Project ID (required)' },
        :result => 'PNG image.',
        :example => { :project => 'id_editor' },
        :ui => '/projects/id_editor'
    }) do
        project_id = params[:project]
        res = @db.select('SELECT icon_type, icon FROM projects.projects').
            condition('id = ?', project_id).
            execute[0]
        if res['icon']
            content_type res['icon_type']
            res['icon']
        else
            redirect('/img/generic-project-icon.svg')
        end
    end

end
