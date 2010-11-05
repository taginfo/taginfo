# web/lib/ui/sources/josm.rb
class Taginfo < Sinatra::Base

    get! '/sources/josm' do
        @title = 'JOSM'
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['JOSM']
        erb :'sources/josm/index'
    end

    get! '/sources/josm/styles' do
        @title = ['Styles', 'JOSM']
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['JOSM', '/sources/josm']
        @breadcrumbs << ['Styles']
        erb :'sources/josm/styles'
    end

    get '/sources/josm/styles/:style' do
        @stylename = h(params[:style])
        @title = [@stylename, 'Styles', 'JOSM']
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['JOSM', '/sources/josm']
        @breadcrumbs << ['Styles', '/sources/josm/styles']
        @breadcrumbs << @stylename
        erb :'sources/josm/style'
    end

end
