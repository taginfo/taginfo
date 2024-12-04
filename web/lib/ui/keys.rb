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

        @projects_count = @db.select('SELECT count(distinct project_id) FROM projects.project_tags').condition('key=?', @key).get_first_i
        @projects = @db.select('SELECT DISTINCT id, coalesce(name, id) AS name FROM projects.projects p JOIN projects.project_tags t ON p.id = t.project_id').condition('t.key=?', @key).order_by('id', 'ASC').execute

        @discardable = {}
        status = @db.select("SELECT approval_status FROM wiki.wikipages_keys WHERE key=?", @key).get_first_value
        @tagstatus = TagStatus[status] if status
        @discardable[:wiki] = (status == 'discardable')

        if @sources.get(:sw)
            @discardable[:id] = false
            @discardable[:josm] = false
            @db.select("SELECT source FROM sw.discardable_tags WHERE key=?", @key).execute.each do |row|
                @discardable[row['source'].to_sym] = true
            end
        end

        javascript_for(:d3)
        javascript "pages/key"
        erb :key
    end

end
