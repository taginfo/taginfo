# web/lib/ui/tags.rb
class Taginfo < Sinatra::Base

    get %r{^/tags/(.*)} do |tag|
        if tag.match(/=/)
            kv = tag.split('=', 2)
        else
            kv = [ tag, '' ]
        end
        if params[:key].nil?
            @key = kv[0]
        else
            @key = params[:key]
        end
        if params[:value].nil?
            @value = kv[1]
        else
            @value = params[:value]
        end
        @tag = @key + '=' + @value

        @key_uri  = escape(@key)

        @title = [escape_html(@key) + '=' + escape_html(@value), t.osm.tags]
        section :tags

        @filter_type = get_filter()
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'
        @filter_xapi = { 'all' => '*', nil => '*', 'nodes' => 'node', 'ways' => 'way', 'relations' => 'relation' }[@filter_type];

        @josm_count = @db.count('josm_style_rules').condition('k = ?', @key).condition('v = ?', @value).get_first_value().to_i
        @wiki_count = @db.count('wiki.wikipages').condition('key=?', @key).condition('value=?', @value).get_first_value().to_i
        if @wiki_count == 0
            @wiki_count_key = @db.count('wiki.wikipages').condition('key=?', @key).condition('value IS NULL').get_first_value().to_i
        end
        @count_all = @db.select("SELECT count_#{@filter_type} FROM db.tags").condition('key = ? AND value = ?', @key, @value).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang=? AND key=? AND value=?", r18n.locale.code, @key, @value).get_first_value())
        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value=?", @key, @value).get_first_value()) if @desc == ''
        if @desc == ''
            @desc = "<span class='empty'>#{ t.pages.tag.no_description_in_wiki }</span>"
        else
            @desc = "<span title='#{ t.pages.tag.description_from_wiki }' tipsy='w'>#{ @desc }</span>"
        end

        @db.select("SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang=? AND key=? AND value=? UNION SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang='en' AND key=? AND value=? LIMIT 1", r18n.locale.code, @key, @value, @key, @value).
            execute() do |row|
                @image_url = build_image_url(row)
            end

        @has_rtype_link = false
        if @key == 'type' && @db.count('relation_types').condition('rtype = ?', @value).get_first_value().to_i > 0
            @has_rtype_link = true
        end

        javascript_for(:flexigrid)
        javascript "#{ r18n.locale.code }/tag"
        erb :tag
    end

end

