# web/lib/ui/projects.rb
class Taginfo < Sinatra::Base

    get '/projects' do
        @title = t.taginfo.projects
        section :projects
        javascript "#{ r18n.locale.code }/projects"
        erb :projects
    end

    get %r{/projects/(.*)} do |project|
        if params[:project].nil?
            @project_id = project
        else
            @project_id = params[:project]
        end

        if @project_id.nil? or @project_id == ''
            redirect(build_link('/projects'))
        end

        @project = @db.select("SELECT * FROM projects.projects").
            condition("id = ?", @project_id).execute()[0]

        if !@project
            halt 404
        end

        @title = [@project['name'], t.taginfo.projects]

        section :projects

        @context[:project] = @project_id

        javascript "#{ r18n.locale.code }/project"
        erb :project
    end

end
