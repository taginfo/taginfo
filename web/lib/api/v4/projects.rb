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
            [:url,         :STRING, 'Project URL'],
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
            condition("fetch_result=?", status).
            condition_if("name LIKE ? ESCAPE '@' OR description LIKE ? ESCAPE '@'", q, q).
            get_first_value().to_i

        res = @db.select('SELECT * FROM projects.projects').
            condition("fetch_result=?", status).
            condition_if("name LIKE ? ESCAPE '@' OR description LIKE ? ESCAPE '@'", q, q).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.name 'lower(name)'
            }.
            paging(@ap).
            execute()

        return JSON.generate({
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :url   => request.url,
            :data  => res.map{ |row| {
                :id          => row['id'],
                :name        => row['name'],
                :url         => row['project_url'],
                :description => row['description'],
            }}
        }, json_opts(params[:format]))
    end

end
