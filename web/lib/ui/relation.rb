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

        javascript "#{ r18n.locale.code }/relation"
        erb :relation
    end

end
