# web/lib/ui/sources/wiki.rb
class Taginfo < Sinatra::Base

    get! '/sources/wiki' do
        @title = 'Wiki'
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['Wiki']
        erb :'sources/wiki/index'
    end

    get! '/sources/wiki/keys' do
        @title = ['Keys', 'Wiki']
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['Wiki', '/sources/wiki']
        @breadcrumbs << ['Keys']

        @languages = @db.execute('SELECT language FROM wiki_languages ORDER by language').map do |row|
            row['language']
        end

        lang_lookup = Hash.new
        @languages.each_with_index do |lang, idx|
            lang_lookup[lang] = idx + 1
        end
        @languages_lookup = @languages.map{ |lang| "'#{lang}': #{lang_lookup[lang]}" }.join(', ')

        erb :'sources/wiki/keys'
    end

end
