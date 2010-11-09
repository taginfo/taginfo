# web/lib/ui/sources/potlatch.rb
class Taginfo < Sinatra::Base

    get! '/sources/potlatch' do
        @title = 'Potlatch'
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['Potlatch']

        erb :'sources/potlatch/index'
    end

    get '/sources/potlatch/categories' do
        @title = 'Potlatch Features'
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['Potlatch', '/sources/potlatch']
        @breadcrumbs << ['Features']

        @categories = @db.execute('SELECT * FROM potlatch.categories ORDER BY name')

        erb :'sources/potlatch/categories'
    end

    get '/sources/potlatch/categories/:category' do
        @category = params[:category]
        @features = @db.execute('SELECT * FROM potlatch.features WHERE category_id=? ORDER BY name', @category)

        erb :'sources/potlatch/category', :layout => false
    end

    get '/sources/potlatch/features/:feature' do
        @feature_name = params[:feature]
        @feature = @db.execute('SELECT * FROM potlatch.features WHERE name=?', @feature_name)[0]
        @tags = @db.execute('SELECT * FROM potlatch.tags WHERE feature_name=? ORDER BY key, value', @feature_name)

        erb :'sources/potlatch/feature', :layout => false
    end

    get %r{/sources/potlatch/icon/(.*)} do |icon|
        content_type :png
        send_file('../../var/sources/potlatch/resources/' + icon)
    end

end
