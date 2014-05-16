# web/lib/ui/keys.rb
class Taginfo < Sinatra::Base

    get %r{^/keys/(.*)} do |key|
        if params[:key].nil?
            @key = key
        else
            @key = params[:key]
        end

        @key_uri  = escape(@key)

        @title = [@key, t.osm.keys]
        section :keys

        @filter_type = get_filter()
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'
        @filter_xapi = { 'all' => '*', nil => '*', 'nodes' => 'node', 'ways' => 'way', 'relations' => 'relation' }[@filter_type];

        @count_all_values = @db.select("SELECT count_#{@filter_type} FROM db.keys").condition('key = ?', @key).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang=? AND key=? AND value IS NULL", r18n.locale.code, @key).get_first_value())
        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value IS NULL", @key).get_first_value()) if @desc == ''
        if @desc == ''
            @desc = "<span class='empty'>#{ t.pages.key.no_description_in_wiki }</span>"
        else
            @desc = "<span title='#{ t.pages.key.description_from_wiki }' tipsy='w'>#{ @desc }</span>"
        end

        @db.select("SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang=? AND key=? AND value IS NULL UNION SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang='en' AND key=? AND value IS NULL LIMIT 1", r18n.locale.code, @key, @key).
            execute() do |row|
                @image_url = build_image_url(row)
            end

        @prevalent_values = @db.select("SELECT value, count_#{@filter_type} AS count FROM tags").
            condition('key=?', @key).
            condition('count > ?', @count_all_values * 0.02).
            order_by([:count], 'DESC').
            execute().map{ |row| { 'value' => row['value'], 'count' => row['count'].to_i } }

        # add "(other)" label for the rest of the values
        sum = @prevalent_values.inject(0){ |sum, x| sum += x['count'] }
        if sum < @count_all_values
            @prevalent_values << { 'value' => '(other)', 'count' => @count_all_values - sum }
        end

        @josm_count = @db.count('josm_style_rules').condition('k = ?', @key).get_first_value().to_i
        @wiki_count = @db.count('wiki.wikipages').condition('value IS NULL').condition('key=?', @key).get_first_value().to_i
        @user_count = @db.select('SELECT users_all FROM db.keys').condition('key=?', @key).get_first_value().to_i
        
        @img_width  = TaginfoConfig.get('geodistribution.width')  * TaginfoConfig.get('geodistribution.scale_image')
        @img_height = TaginfoConfig.get('geodistribution.height') * TaginfoConfig.get('geodistribution.scale_image')

        javascript_for(:flexigrid, :cookie, :d3)
        javascript "#{ r18n.locale.code }/key"
        erb :key
    end

end

