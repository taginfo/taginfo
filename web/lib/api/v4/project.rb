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
            [:description, :STRING, 'Description'],
            [:doc_url,     :STRING, 'Documentation URL'],
            [:icon_url,    :STRING, 'Icon URL']
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'key', :sortorder => 'asc' },
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
                :description => row['description'],
                :doc_url     => row['doc_url'],
                :icon_url    => row['icon_url']
            }}
        }, json_opts(params[:format]))
    end

    api(4, 'project/icon', {
        :description => 'Access logo icon for project.',
        :parameters => { :project => 'Project ID' },
        :result => 'Redirect to project image.',
        :example => { :project => 'osmcoastline' },
        :ui => '/projects'
    }) do
        project_id = params[:project]
        url = @db.select('SELECT icon_url FROM projects.projects').
            condition('id = ?', project_id).
            get_first_value()
        if url.nil? || url == ''
            redirect '/img/generic_project_icon.png'
        else
            redirect url
        end
    end

end
