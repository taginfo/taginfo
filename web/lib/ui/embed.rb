# web/lib/ui/embed.rb
class Taginfo < Sinatra::Base

    get '/embed/key' do
        @key = params[:key]
        @dbkey = @db.select("SELECT * FROM db.keys").condition('key = ?', @key).execute()[0]
        erb :'embed/key', :layout => :'embed/layout'
    end

    get '/embed/tag' do
        @key = params[:key]
        @value = params[:value]
        @dbtag = @db.select("SELECT * FROM db.tags").condition('key = ?', @key).condition('value = ?', @value).execute()[0]
        @dbkey = @db.select("SELECT * FROM db.keys").condition('key = ?', @key).execute()[0]
        erb :'embed/tag', :layout => :'embed/layout'
    end

    get '/embed/relation' do
        @rtype = params[:rtype]
        @dbrtype = @db.select("SELECT * FROM db.relation_types").condition('rtype = ?', @rtype).execute()[0]
        @roles = @db.select("SELECT role FROM db.prevalent_roles WHERE rtype=? ORDER BY count DESC LIMIT 10", @rtype).execute().map{ |row| row['role'] == '' ? '<i>(empty role)</i>' : row['role'] }
        erb :'embed/relation', :layout => :'embed/layout'
    end

end
