# web/lib/api/v4/projects.rb
class Taginfo < Sinatra::Base

    api(4, 'projects/all', {
        :description => 'Get list of all projects using OSM tags known to taginfo.',
        :parameters => { :status => 'Only show projects with given status (default is "OK")', :query => 'Only show projects matching this query (substring match, optional).' },
        :paging => :optional,
        :sort => %w( name ),
        :result => paging_results([
            [:id,          :STRING, 'Project id'],
            [:name,        :STRING, 'Project name'],
            [:project_url, :STRING, 'Project URL'],
            [:icon_url,    :STRING, 'Icon URL'],
            [:doc_url,     :STRING, 'Documentation URL'],
            [:description, :STRING, 'Project description']
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'name', :sortorder => 'asc' },
        :ui => '/projects'
    }) do
        if params[:status]
            status = params[:status]
        else
            status = 'OK'
        end

        q = like_contains(params[:query])
        total = @db.count('projects.projects').
            condition("status=?", status).
            condition_if("name LIKE ? ESCAPE '@' OR description LIKE ? ESCAPE '@'", q, q).
            get_first_i

        res = @db.select('SELECT * FROM projects.projects').
            condition("status=?", status).
            condition_if("name LIKE ? ESCAPE '@' OR description LIKE ? ESCAPE '@'", q, q).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.name 'lower(name)'
            }.
            paging(@ap).
            execute()

        return generate_json_result(total,
            res.map{ |row| {
                :id          => row['id'],
                :name        => row['name'],
                :project_url => row['project_url'],
                :icon_url    => row['icon_url'],
                :doc_url     => row['doc_url'],
                :description => row['description'],
            }}
        )
    end

end
