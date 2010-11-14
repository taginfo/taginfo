# web/lib/ui/test.rb
class Taginfo < Sinatra::Base

    get! '/test' do
        @title = 'Test'
        @breadcrumbs << 'Test'
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
        @breadcrumbs << [ 'Test', '/test' ]
        @breadcrumbs << 'Wiki Import'
        @invalid_page_titles = @db.select('SELECT * FROM invalid_page_titles').execute()
        erb :'test/wiki_import'
    end

    get %r{^/test/keys/(.*)} do |key|
        if params[:key].nil?
            @key = key
        else
            @key = params[:key]
        end

        @key_html = escape_html(@key)
        @key_uri  = escape(@key)
        @key_json = @key.to_json
        @key_pp   = pp_key(@key)

        @title = [@key_html, 'Keys']
        @breadcrumbs << ['Keys', '/keys']
        @breadcrumbs << @key_html

        @filter_type = get_filter()
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'

        @count_all_values = @db.select("SELECT count_#{@filter_type} FROM db.keys").condition('key = ?', @key).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value IS NULL", @key).get_first_value())
        @desc = '<i>no description in wiki</i>' if @desc == ''

        @prevalent_values = @db.select("SELECT value, count_#{@filter_type} AS count FROM tags").
            condition('key=?', @key).
            condition('count > ?', @count_all_values * 0.02).
            order_by(:count, 'DESC').
            execute().map{ |row| [{ 'value' => row['value'], 'count' => row['count'].to_i }] }

        # add "(other)" label for the rest of the values
        sum = @prevalent_values.inject(0){ |sum, x| sum += x[0]['count'] }
        if sum < @count_all_values
            @prevalent_values << [{ 'value' => '(other)', 'count' => @count_all_values - sum }]
        end

        @wiki_count = @db.count('wiki.wikipages').condition('value IS NULL').condition('key=?', @key).get_first_value().to_i
        
        (@merkaartor_type, @merkaartor_link, @merkaartor_selector) = @db.select('SELECT tag_type, link, selector FROM merkaartor.keys').condition('key=?', @key).get_columns(:tag_type, :link, :selector)
        @merkaartor_images = [:node, :way, :area, :relation].map{ |type|
            name = type.to_s.capitalize
            '<img src="/img/types/' + (@merkaartor_selector =~ /Type is #{name}/ ? type.to_s : 'none') + '.16.png" alt="' + name + '" title="' + name + '"/>'
        }.join('&nbsp;')

        @merkaartor_values = @db.select('SELECT value FROM merkaartor.tags').condition('key=?', @key).order_by(:value).execute().map{ |row| row['value'] }

        @merkaartor_desc = @db.select('SELECT lang, description FROM key_descriptions').condition('key=?', @key).order_by(:lang).execute()

        erb :'test/key'
    end

end
