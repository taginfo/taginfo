# web/lib/ui/sources/josm.rb
class Taginfo < Sinatra::Base

    get! '/sources/josm' do
        @title = 'JOSM'
        erb :'sources/josm/index'
    end

    get! '/sources/josm/styles' do
        @title = ['Styles', 'JOSM']
        erb :'sources/josm/styles'
    end

    get '/sources/josm/styles/:style' do
        @stylename = h(params[:style])
        @title = [@stylename, 'Styles', 'JOSM']
        erb :'sources/josm/style'
    end

end
