# web/lib/ui/test.rb
class Taginfo < Sinatra::Base

    get! '/test' do
        @title = 'Test'
        erb :'test/index'
    end

    get '/test/wiki_import' do
        section :test
        @title = ['Wiki Import', 'Test']
        @problems = @db.select('SELECT * FROM problems ORDER BY location, reason, lang, key, value').execute()
        erb :'test/wiki_import'
    end

end
