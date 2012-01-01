# web/lib/ui/sources/wiki.rb
class Taginfo < Sinatra::Base

    get! '/sources/wiki' do
        @title = 'Wiki'
        erb :'sources/wiki/index'
    end

end
