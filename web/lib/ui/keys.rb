# web/lib/ui/keys.rb
class Taginfo < Sinatra::Base

    get %r{/keys/(.*)} do |key|
        @key = if params[:key].nil?
                   key
               else
                   params[:key]
               end

        @key_uri = escape(@key)

        @title = [@key, t.osm.keys]
        section :keys

        @filter_type = get_filter
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'
        @filter_xapi = { 'all' => '*', nil => '*', 'nodes' => 'node', 'ways' => 'way', 'relations' => 'relation' }[@filter_type]

        @count_all_values = @db.select("SELECT count_#{@filter_type} FROM db.keys").condition('key = ?', @key).get_first_i

        @desc = wrap_description(t.pages.key, get_key_description(@key))

        @db.select("SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang=? AND key=? AND value IS NULL UNION SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang='en' AND key=? AND value IS NULL LIMIT 1", r18n.locale.code, @key, @key).
            execute do |row|
                @image_url = build_image_url(row)
            end

        @wiki_count = @db.count('wiki.wikipages').condition('key=? AND value IS NULL', @key).get_first_i
        @user_count = @db.select('SELECT users_all FROM db.keys').condition('key=?', @key).get_first_i

        @img_width  = @taginfo_config.get('geodistribution.width')  * @taginfo_config.get('geodistribution.scale_image')
        @img_height = @taginfo_config.get('geodistribution.height') * @taginfo_config.get('geodistribution.scale_image')

        @context[:key] = @key
        @context[:countAllValues] = @count_all_values

        if @sources.get(:chronology)
            @has_chronology = @db.count('keys_chronology').condition('key=?', @key).get_first_i > 0
        end

        @wikipages = @db.select("SELECT DISTINCT lang, title FROM wiki.wikipages WHERE key=? AND value IS NULL ORDER BY lang", @key).execute.map do |row|
            lang = row['lang']
            {
                :lang    => lang,
                :title   => row['title'],
                :english => ::Language[lang].english_name,
                :native  => ::Language[lang].native_name,
                :dir     => direction_from_lang_code(lang)
            }
        end

        @wikipage_en = @wikipages.find{ |row| row[:lang] == 'en' }

        javascript_for(:d3)
        javascript "pages/key"
        erb :key
    end

end
