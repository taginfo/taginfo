# web/lib/ui/sources/merkaartor.rb
class Taginfo < Sinatra::Base

    get! '/sources/merkaartor/' do
        @title = 'Merkaartor'
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['Merkaartor']
        erb :'sources/merkaartor/index'
    end

end
