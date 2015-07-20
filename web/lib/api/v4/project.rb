# web/lib/api/v4/project.rb
class Taginfo < Sinatra::Base

    api(4, 'project/tags', {
        :description => 'Get list of all keys/tags used by a project.',
        :parameters => { :project => 'Project ID' },
        :paging => :optional,
        :sort => %w( tag ),
        :result => paging_results([
            [:key,         :STRING, 'Key'],
            [:value,       :STRING, 'Value'],
            [:on_node,     :BOOL,   'For nodes?'],
            [:on_way,      :BOOL,   'For ways?'],
            [:on_relation, :BOOL,   'For relations?'],
            [:on_area,     :BOOL,   'For areas?'],
            [:description, :STRING, 'Description'],
            [:doc_url,     :STRING, 'Documentation URL'],
            [:icon_url,    :STRING, 'Icon URL']
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'tag', :sortorder => 'asc' },
        :ui => '/projects/id_editor'
    }) do
        project_id = params[:project]

        q = like_contains(params[:query])
        total = @db.count('projects.project_tags').
            condition("project_id=?", project_id).
            condition_if("key LIKE ? ESCAPE '@' OR value LIKE ? ESCAPE '@'", q, q).
            get_first_value().to_i

        res = @db.select('SELECT * FROM projects.project_tags').
            condition("project_id=?", project_id).
            condition_if("key LIKE ? ESCAPE '@' OR value LIKE ? ESCAPE '@'", q, q).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.tag :key
                o.tag :value
            }.
            paging(@ap).
            execute()

        return JSON.generate({
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :url   => request.url,
            :data  => res.map{ |row| {
                :key         => row['key'],
                :value       => row['value'],
                :on_node     => row['on_node'].to_i     == 1,
                :on_way      => row['on_way'].to_i      == 1,
                :on_relation => row['on_relation'].to_i == 1,
                :on_area     => row['on_area'].to_i     == 1,
                :description => row['description'],
                :doc_url     => row['doc_url'],
                :icon_url    => row['icon_url']
            }}
        }, json_opts(params[:format]))
    end

end
