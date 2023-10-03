# web/lib/api/v4/projects.rb
class Taginfo < Sinatra::Base

    api(4, 'projects/all', {
        :description => 'Get list of all projects using OSM tags known to taginfo.',
        :parameters => {
            :status => 'Only show projects with given status (default is "OK")',
            :query => 'Only show projects where name or description matches this query (substring match, optional).'
        },
        :paging => :optional,
        :sort => %w[ name unique_keys unique_values ],
        :result => paging_results([
            [:id,          :STRING, 'Project id'],
            [:name,        :STRING, 'Project name'],
            [:project_url, :STRING, 'Project URL'],
            [:icon_url,    :STRING, 'Icon URL'],
            [:doc_url,     :STRING, 'Documentation URL'],
            [:description, :STRING, 'Project description'],
            [:key_entries, :INT,    'Key entries for this project'],
            [:tag_entries, :INT,    'Tag entries for this project'],
            [:unique_keys, :INT,    'Unique keys known to this project'],
            [:unique_tags, :INT,    'Unique tags known to this project']
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

        res = @db.select('SELECT id, name, project_url, icon_url, doc_url, description, key_entries, tag_entries, unique_keys, unique_tags FROM projects.projects').
            condition("status=?", status).
            condition_if("name LIKE ? ESCAPE '@' OR description LIKE ? ESCAPE '@'", q, q).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.name 'lower(name)'
                o.unique_keys
                o.unique_keys :unique_tags
                o.unique_tags
                o.unique_tags :unique_keys
            end.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                :id          => row['id'],
                :name        => row['name'],
                :project_url => row['project_url'],
                :icon_url    => row['icon_url'],
                :doc_url     => row['doc_url'],
                :description => row['description'],
                :key_entries => row['key_entries'],
                :tag_entries => row['tag_entries'],
                :unique_keys => row['unique_keys'],
                :unique_tags => row['unique_tags']
            }
            end
        )
    end

    api(4, 'projects/keys', {
        :description => 'Get list of all keys used by at least one project.',
        :parameters => { :query => 'Only show keys matching this query (substring match, optional).' },
        :paging => :optional,
        :sort => %w[ key projects in_wiki count_all ],
        :result => paging_results([
            [:key,                :STRING, 'Key'],
            [:projects,           :INT,    'Number of projects using this key'],
            [:in_wiki,            :BOOL,   'Is there at least one wiki page for this key?'],
            [:count_all,          :INT,    'Number of objects in the OSM database with this key.'],
            [:count_all_fraction, :FLOAT,  'Number of objects in relation to all objects.']
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'key', :sortorder => 'asc' },
        :ui => '/projects#keys'
    }) do
        q = like_contains(params[:query])
        total = @db.count('project_unique_keys').
            condition_if("key LIKE ? ESCAPE '@'", q).
            get_first_i

        res = @db.select('SELECT * FROM project_unique_keys').
            condition_if("key LIKE ? ESCAPE '@'", q).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.key
                o.projects
                o.projects :key
                o.in_wiki
                o.in_wiki :key
                o.count_all
                o.count_all :key
            end.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                :key                => row['key'],
                :projects           => row['projects'],
                :in_wiki            => row['in_wiki'],
                :count_all          => row['count_all'],
                :count_all_fraction => (row['count_all'].to_f / @db.stats('objects')).round(4)
            }
            end
        )
    end

    api(4, 'projects/tags', {
        :description => 'Get list of all tags used by at least one project.',
        :parameters => { :query => 'Only show tags matching this query (substring match, optional).' },
        :paging => :optional,
        :sort => %w[ key value projects in_wiki count_all ],
        :result => paging_results([
            [:key,                :STRING, 'Key'],
            [:value,              :STRING, 'Value'],
            [:projects,           :INT,    'Number of projects using this tag'],
            [:in_wiki,            :BOOL,   'Is there at least one wiki page for this tag?'],
            [:count_all,          :INT,    'Number of objects in the OSM database with this tag.'],
            [:count_all_fraction, :FLOAT,  'Number of objects in relation to all objects.']
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'tag', :sortorder => 'asc' },
        :ui => '/projects#tags'
    }) do
        q = like_contains(params[:query])
        total = @db.count('project_unique_tags').
            condition_if("key LIKE ? ESCAPE '@' OR value LIKE ? ESCAPE '@'", q, q).
            get_first_i

        res = @db.select('SELECT * FROM project_unique_tags').
            condition_if("key LIKE ? ESCAPE '@' OR value LIKE ? ESCAPE '@'", q, q).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.tag :key
                o.tag :value
                o.projects
                o.projects :key
                o.in_wiki
                o.in_wiki :key
                o.count_all
                o.count_all :key
            end.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                :key                => row['key'],
                :value              => row['value'],
                :projects           => row['projects'],
                :in_wiki            => row['in_wiki'],
                :count_all          => row['count_all'],
                :count_all_fraction => (row['count_all'].to_f / @db.stats('objects')).round(4)
            }
            end
        )
    end

end
