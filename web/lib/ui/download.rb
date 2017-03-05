# web/lib/ui/download.rb
class Taginfo < Sinatra::Base

    get '/download' do
        @title = t.taginfo['download']
        section 'download'
        erb :download
    end

end
