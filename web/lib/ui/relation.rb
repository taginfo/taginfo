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

        @desc = 'XXX'

        @count_relation_roles = @db.count('relation_roles').
            condition("rtype=?", rtype).
            get_first_value().to_i

        javascript "#{ r18n.locale.code }/relation"
        erb :relation
    end

end
