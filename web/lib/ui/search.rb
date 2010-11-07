# web/lib/ui/search.rb
class Taginfo < Sinatra::Base

    get '/search' do
        @title = 'Search results'
        @breadcrumbs << @title

        @escaped_search_string = escape_html(params[:search])

        @key = @db.select('SELECT key FROM keys').
            condition('key = ?', params[:search]).
            get_first_value()

        @substring_keys = @db.select('SELECT key FROM keys').
            condition("key LIKE '%' || ? || '%' AND key != ?", params[:search], params[:search]).
            order_by(:key).
            execute().
            map{ |row| row['key'] }

        erb :search
    end

end
