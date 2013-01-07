# web/lib/api/v4/tags.rb
class Taginfo < Sinatra::Base

    api(4, 'tags/popular', {
        :description => 'Get list of most often used tags.',
        :parameters => { :query => 'Only show tags matching this query (substring match in key and value, optional).' },
        :paging => :optional,
        :sort => %w( tag count_all count_nodes count_ways count_relations ),
        :result => paging_results([
            [:key,                      :STRING, 'Key'],
            [:value,                    :STRING, 'Value'],
            [:count_all,                :INT,    'Number of objects in the OSM database with this tag.'],
            [:count_all_fraction,       :FLOAT,  'Number of objects in relation to all objects.'],
            [:count_nodes,              :INT,    'Number of nodes in the OSM database with this tag.'],
            [:count_nodes_fraction,     :FLOAT,  'Number of nodes in relation to all tagged nodes.'],
            [:count_ways,               :INT,    'Number of ways in the OSM database with this tag.'],
            [:count_ways_fraction,      :FLOAT,  'Number of ways in relation to all ways.'],
            [:count_relations,          :INT,    'Number of relations in the OSM database with this tag.'],
            [:count_relations_fraction, :FLOAT,  'Number of relations in relation to all relations.']
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'tag', :sortorder => 'asc' },
        :ui => '/tags'
    }) do

        total = @db.count('db.selected_tags').
            condition_if("(skey LIKE '%' || ? || '%') OR (svalue LIKE '%' || ? || '%')", params[:query], params[:query]).
            get_first_value().to_i
        
        res = @db.select('SELECT * FROM db.selected_tags').
            condition_if("(skey LIKE '%' || ? || '%') OR (svalue LIKE '%' || ? || '%')", params[:query], params[:query]).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.tag :skey
                o.tag :svalue
                o.count_all
                o.count_nodes
                o.count_ways
                o.count_relations
            }.
            paging(@ap).
            execute()

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map{ |row| {
                :key                      => row['skey'],
                :value                    => row['svalue'],
                :count_all                => row['count_all'].to_i,
                :count_all_fraction       => (row['count_all'].to_f / @db.stats('objects')).round_to(4),
                :count_nodes              => row['count_nodes'].to_i,
                :count_nodes_fraction     => (row['count_nodes'].to_f / @db.stats('nodes_with_tags')).round_to(4),
                :count_ways               => row['count_ways'].to_i,
                :count_ways_fraction      => (row['count_ways'].to_f / @db.stats('ways')).round_to(4),
                :count_relations          => row['count_relations'].to_i,
                :count_relations_fraction => (row['count_relations'].to_f / @db.stats('relations')).round_to(4),
            } }
        }.to_json
    end

end
