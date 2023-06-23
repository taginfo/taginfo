# web/lib/ui/tags.rb
class Taginfo < Sinatra::Base

    get %r{/tags/(.*)} do |tag|
        kv = if tag.match(/=/)
                 tag.split('=', 2)
             else
                 [ tag, '' ]
             end
        @key = if params[:key].nil?
                   kv[0]
               else
                   params[:key]
               end
        @value = if params[:value].nil?
                     kv[1]
                 else
                     params[:value]
                 end
        @tag = @key + '=' + @value

        @key_uri = escape(@key)
        @value_uri = escape(@value)

        @title = [@key + '=' + @value, t.osm.tags]
        section :tags

        @filter_type = get_filter
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'
        @filter_xapi = { 'all' => '*', nil => '*', 'nodes' => 'node', 'ways' => 'way', 'relations' => 'relation' }[@filter_type]

        @wiki_count = @db.count('wiki.wikipages').condition('key=? AND value=?', @key, @value).get_first_i
        if @wiki_count == 0
            @wiki_count_key = @db.count('wiki.wikipages').condition('key=? AND value IS NULL', @key).get_first_i
        end
        @count_all = @db.select("SELECT count_#{@filter_type} FROM db.tags").condition('key = ? AND value = ?', @key, @value).get_first_i

        @desc = wrap_description(t.pages.tag, get_tag_description(@key, @value))

        @db.select("SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang=? AND key=? AND value=? UNION SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang='en' AND key=? AND value=? LIMIT 1", r18n.locale.code, @key, @value, @key, @value).
            execute do |row|
                @image_url = build_image_url(row)
            end

        @has_rtype_link = false
        if @key == 'type' && @db.count('relation_types').condition('rtype = ?', @value).get_first_i > 0
            @has_rtype_link = true
        end

        @has_map = @db.count('tag_distributions').condition('key=? AND value=?', @key, @value).get_first_i > 0

        if @sources.get(:chronology)
            @has_chronology = @db.count('tags_chronology').condition('key=? AND value=?', @key, @value).get_first_i > 0
        end

        @img_width  = @taginfo_config.get('geodistribution.width')  * @taginfo_config.get('geodistribution.scale_image')
        @img_height = @taginfo_config.get('geodistribution.height') * @taginfo_config.get('geodistribution.scale_image')

        @links = get_links(@key, @value)

        @context[:key] = @key
        @context[:value] = @value

        javascript_for(:d3)
        javascript "pages/tag"
        erb :tag
    end

end
