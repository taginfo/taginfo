# web/lib/ui/sources/db.rb
class Taginfo < Sinatra::Base

    get! '/sources/db/' do
        @title = 'Database'
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['Database']
        erb :'sources/db'
    end

end
