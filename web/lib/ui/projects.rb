# web/lib/ui/projects.rb
class Taginfo < Sinatra::Base

    get '/projects' do
        @title = t.taginfo.projects
        javascript_for(:flexigrid)
        javascript "#{ r18n.locale.code }/projects"
        erb :projects
    end

    get %r{^/projects/(.*)} do |project|
        if params[:project].nil?
            @project_id = project
        else
            @project_id = params[:project]
        end

        @project = @db.select("SELECT * FROM projects.projects").
            condition("id = ?", @project_id).execute()[0]

        if !@project
            halt 404
        end

        @title = [@project['name'], t.taginfo.projects]

        section :projects

        javascript_for(:flexigrid)
        javascript "#{ r18n.locale.code }/project"
        erb :project
    end

end
