# test.rb
class Taginfo < Sinatra::Base

    get! '/test' do
        erb :'test/index'
    end

    get! '/test/tags' do
        @title = ['Tags', 'Test']
        @breadcrumbs << [ 'Test', '/test' ]
        @breadcrumbs << 'Tags'
        limit = 300;
        (@min, @max) = @db.select('SELECT min(count) AS min, max(count) AS max FROM popular_keys').get_columns(:min, :max)
        @tags = @db.select("SELECT key, count, (count - ?) / (? - ?) AS scale, in_wiki, in_josm FROM popular_keys ORDER BY count DESC LIMIT #{limit}", @min.to_f, @max, @min).
            execute().
            each_with_index{ |tag, idx| tag['pos'] = (limit - idx) / limit.to_f }.
            sort_by{ |row| row['key'] }
        erb :'test/tags'
    end

    get '/test/wiki_import' do
        @title = ['Wiki Import', 'Test']
        @breadcrumbs << [ 'Wiki Import', '/test' ]
        @breadcrumbs << 'Tags'
        @invalid_page_titles = @db.select('SELECT * FROM invalid_page_titles').execute()
        erb :'test/wiki_import'
    end

end
