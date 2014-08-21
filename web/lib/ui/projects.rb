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

        @project = Project.get(@project_id)

        if @project
            @title = [h(@project.name), t.taginfo.projects]
        end

        section :projects

        javascript_for(:flexigrid)
        javascript "#{ r18n.locale.code }/project"
        erb :project
    end

end
