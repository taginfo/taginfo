# web/lib/ui/search.rb
class Taginfo < Sinatra::Base

    # The search results page
    get '/search' do
        @title = t.pages.search.title

        @query = params[:q]
        if @query =~ /(.*)=(.*)/
            javascript "pages/search_tags"
            erb :search_tags
        else
            javascript "pages/search"
            erb :search
        end
    end

    # Return opensearch description (see www.opensearch.org)
    get '/search/opensearch.xml' do
        content_type :opensearch
        opensearch = <<END_XML
<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
    <ShortName>#{ @taginfo_config.get('opensearch.shortname') }</ShortName>
    <Description>#{ @taginfo_config.get('opensearch.description') }</Description>
    <Tags>#{ @taginfo_config.get('opensearch.tags') }</Tags>
    <Contact>#{ @taginfo_config.get('opensearch.contact') }</Contact>
    <Url type="application/x-suggestions+json" rel="suggestions" template="__URL__/search/suggest?term={searchTerms}"/>
    <Url type="text/html" method="get" template="__URL__/search?q={searchTerms}"/>
    <Url type="application/opensearchdescription+xml" rel="self" template="__URL__/search/opensearch.xml"/>
    <Image height="16" width="16" type="image/x-icon">__URL__/favicon.ico</Image>
</OpenSearchDescription>
END_XML
        return opensearch.gsub(/__URL__/, @taginfo_config.get('instance.url'))
    end

    # Returns search suggestions as per OpenSearch standard
    get '/search/suggest' do
        query = params[:term]
        format = params[:format]

        sel = @db.select('SELECT * FROM suggestions').
            order_by([:score], 'DESC').
            limit(10)

        if query =~ /^=(.*)/
            value = $1
            res = sel.
                condition_if("value LIKE ? ESCAPE '@'", like_prefix(value)).
                execute().
                map{ |row| row['key'] + '=' + row['value'].to_s }
        elsif query =~ /^([^=]+)=(.*)/
            key = $1
            value = $2
            res = sel.
                condition_if("key LIKE ? ESCAPE '@'", like_prefix(key)).
                condition_if("value LIKE ? ESCAPE '@'", like_prefix(value)).
                execute().
                map{ |row| row['key'] + '=' + row['value'].to_s }
        else
            res = sel.
                condition_if("key LIKE ? ESCAPE '@'", like_prefix(query)).
                is_null('value').
                execute().
                map{ |row| row['key'] }
        end

        content_type :json
        if format == 'simple'
            # simple format is used by the search box on the website itself,
            # it is just a list of suggestions
            return res.to_json + "\n"
        else
            # this is the OpenSearch standard format
            return [
                query, # the query string
                res, # the list of suggestions
                res.map{ |item| '' }, # the standard says this is for descriptions, we don't have any so this is empty
                res.map{ |item| @taginfo_config.get('instance.url') + '/tags/' + item } # the page this search should got to (ignored by FF, Chrome)
            ].to_json + "\n"
        end
    end

end
