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

end
