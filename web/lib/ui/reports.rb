# web/lib/ui/reports.rb
class Taginfo < Sinatra::Base

    get! '/reports/' do
        @title = 'Reports'
        @breadcrumbs << @title
        erb :'reports/index'
    end

    #--------------------------------------------------------------------------

    ['Frequently Used Keys Without Wiki Page', 'Characters in Keys'].each do |title|
        name = title.gsub(/ /, '_').downcase
        get '/reports/' + name do
            @title = title
            @breadcrumbs << [ 'Reports', '/reports' ]
            @breadcrumbs << title
            erb ('reports/' + name).to_sym
        end
    end

end
