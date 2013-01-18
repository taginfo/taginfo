# web/lib/ui/help.rb
class Taginfo < Sinatra::Base

    get '/help/keyboard' do
        erb :'help/keyboard', :layout => false
    end

    get '/help/search' do
        erb :'help/search', :layout => false
    end

end
