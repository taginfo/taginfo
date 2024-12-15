# web/lib/ui/sources.rb
class Taginfo < Sinatra::Base

    get! '/sources' do
        @title = t.taginfo.sources
        section :sources
        erb :sources
    end

    def get_source_page(source, page)
        @source = @sources.get(source.to_sym)
        halt 404 unless @source

        halt 404 unless File.exist?("views/sources/#{ @source.id }/#{ page }.erb")

        @title = [@source.name, t.taginfo.sources]
        section :sources
        if File.exist?("public/js/pages/sources/#{ @source.id }/#{ page }.js")
            javascript "pages/sources/#{ @source.id }/#{ page }"
        end
    end

    get %r{/sources/([a-z]+)} do |source|
        get_source_page(source, 'index')
        erb :'sources/layout' do
            erb "sources/#{ @source.id }/index".to_sym
        end
    end

    get %r{/sources/([a-z]+)/(.*)} do |source, page|
        get_source_page(source, page)
        erb "sources/#{ @source.id }/#{ page }".to_sym
    end

end
