# web/lib/ui/embed.rb
class Taginfo < Sinatra::Base

    get '/embed/key' do
        @key = params[:key]
        @count = @db.select("SELECT count_all FROM db.keys").condition('key = ?', @key).get_first_value().to_i
        erb :'embed/key', :layout => false
    end

    get '/embed/tag' do
        @key = params[:key]
        @value = params[:value]
        @count = @db.select("SELECT count_all FROM db.tags").condition('key = ?', @key).condition('value = ?', @value).get_first_value().to_i
        erb :'embed/tag', :layout => false
    end

end
