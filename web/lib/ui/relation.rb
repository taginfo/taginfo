# web/lib/ui/relations.rb
class Taginfo < Sinatra::Base

    get %r{^/relations/(.*)} do |rtype|
        if params[:rtype].nil?
            @rtype = rtype
        else
            @rtype = params[:rtype]
        end

        @title = [escape_html(@rtype), t.osm.relations]
        section :relations

        @count_all_values = @db.select("SELECT count_relations FROM db.keys").condition('key = ?', @rtype).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.relation_pages WHERE lang=? AND rtype=?", r18n.locale.code, @rtype).get_first_value())
        @desc = h(@db.select("SELECT description FROM wiki.relation_pages WHERE lang='en' AND rtype=?", @rtype).get_first_value()) if @desc == ''
        if @desc == ''
            @desc = "<span class='empty'>#{ t.pages.relation.no_description_in_wiki }</span>"
        else
            @desc = "<span title='#{ t.pages.relation.description_from_wiki }' tipsy='w'>#{ @desc }</span>"
        end

        @db.select("SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.relation_pages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang=? AND rtype=? UNION SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.relation_pages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang='en' AND rtype=? LIMIT 1", r18n.locale.code, @rtype, @rtype).
            execute() do |row|
                @image_url = build_image_url(row)
            end

        @count_relation_roles = @db.count('relation_roles').
            condition("rtype=?", rtype).
            get_first_value().to_i

        javascript "#{ r18n.locale.code }/relation"
        erb :relation
    end

end
