# web/lib/ui/test.rb
class Taginfo < Sinatra::Base

    get! '/test' do
        @title = 'Test'
        erb :'test/index'
    end

    get '/test/wiki_import' do
        section :test
        @title = ['Wiki Import', 'Test']
        @invalid_page_titles = @db.select('SELECT * FROM invalid_page_titles').execute()
        @invalid_image_titles = @db.select('SELECT * FROM invalid_image_titles').execute()
        erb :'test/wiki_import'
    end

    get! '/test/potlatch' do
        @title = 'Potlatch'

        erb :'test/potlatch/index'
    end

    get '/test/potlatch/categories' do
        @title = 'Potlatch Features'

        @categories = @db.execute('SELECT * FROM potlatch.categories ORDER BY name')

        erb :'test/potlatch/categories'
    end

    get '/test/potlatch/categories/:category' do
        @category = params[:category]
        @features = @db.execute('SELECT * FROM potlatch.features WHERE category_id=? ORDER BY name', @category)

        erb :'test/potlatch/category', :layout => false
    end

    get '/test/potlatch/features/:feature' do
        @feature_name = params[:feature]
        @feature = @db.execute('SELECT * FROM potlatch.features WHERE name=?', @feature_name)[0]
        @tags = @db.execute('SELECT * FROM potlatch.tags WHERE feature_name=? ORDER BY key, value', @feature_name)

        erb :'test/potlatch/feature', :layout => false
    end

    get %r{/test/potlatch/icon/(.*)} do |icon|
        content_type :png
        send_file('../../var/sources/potlatch/resources/' + icon)
    end

end
