# web/lib/ui/relations.rb
class Taginfo < Sinatra::Base

    get %r{^/relations/(.*)} do |rtype|
        if params[:rtype].nil?
            @rtype = rtype
        else
            @rtype = params[:rtype]
        end

        @rtype_uri  = escape(@rtype)

        @title = [@rtype, t.osm.relations]
        section :relations

        @wiki_count = @db.count('wiki.relation_pages').condition('rtype=?', @rtype).get_first_i
        @count_all_values = @db.select("SELECT count FROM db.relation_types").condition('rtype = ?', @rtype).get_first_i

        @desc = h(get_relation_description(r18n.locale.code, @rtype))
        if @desc == ''
            @desc = "<span class='empty'>#{ t.pages.relation.no_description_in_wiki }</span>"
        else
            @desc = "<span title='#{ t.pages.relation.description_from_wiki }' tipsy='w'>#{ @desc }</span>"
        end

        @db.select("SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.relation_pages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang=? AND rtype=? UNION SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.relation_pages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang='en' AND rtype=? LIMIT 1", r18n.locale.code, @rtype, @rtype).
            execute() do |row|
                @image_url = build_image_url(row)
            end

        @count_relation_roles = @db.count('relation_roles').condition("rtype=?", @rtype).get_first_i

        sum_count_all = @db.select("SELECT members_all FROM db.relation_types WHERE rtype=?", @rtype).get_first_i

        @roles = []
        sum = { 'nodes' => 0, 'ways' => 0, 'relations' => 0 }
        @db.select("SELECT * FROM db.relation_roles WHERE rtype=? ORDER BY count_all DESC", @rtype).execute() do |row|
            %w( nodes ways relations ).each do |type|
                count = row["count_#{ type }"].to_i
                if row['count_all'].to_i < sum_count_all * 0.01
                    sum[type] += count
                else
                    @roles << { :role => row['role'], :type => type, :value => count }
                end
            end
        end
        if sum['nodes'] > 0 || sum['ways'] > 0 || sum['relations'] > 0
            %w( nodes ways relations ).each do |type|
                @roles << { :role => '...', :type => type, :value => sum[type] }
            end
        end

        javascript_for(:flexigrid, :d3)
        javascript "#{ r18n.locale.code }/relation"
        erb :relation
    end

end
