# web/lib/api/v4/tags.rb
class Taginfo < Sinatra::Base

    api(4, 'tags/list', {
        :description => 'Get information on given tags or all tags documented on the wiki with given key.',
        :parameters => { :key => 'Key (optional)', :tags => 'Comma-separated list of tags in format key1=value1a,value1b,...,key2=value2a,value2b,... (optional).' },
        :paging => :no,
        :result => no_paging_results([
            [:key,                      :STRING, 'Key'],
            [:value,                    :STRING, 'Value'],
            [:in_wiki,                  :BOOL,   'In there a page in the wiki for this tag?'],
            [:count_all,                :INT,    'Number of objects in the OSM database with this tag.'],
            [:count_all_fraction,       :FLOAT,  'Number of objects in relation to all objects.'],
            [:count_nodes,              :INT,    'Number of nodes in the OSM database with this tag.'],
            [:count_nodes_fraction,     :FLOAT,  'Number of nodes in relation to all tagged nodes.'],
            [:count_ways,               :INT,    'Number of ways in the OSM database with this tag.'],
            [:count_ways_fraction,      :FLOAT,  'Number of ways in relation to all ways.'],
            [:count_relations,          :INT,    'Number of relations in the OSM database with this tag.'],
            [:count_relations_fraction, :FLOAT,  'Number of relations in relation to all relations.'],
            [:on_node,                  :BOOL,   'Is this a tag for nodes?'],
            [:on_way,                   :BOOL,   'Is this a tag for ways?'],
            [:on_area,                  :BOOL,   'Is this a tag for areas?'],
            [:on_relation,              :BOOL,   'Is this a tag for relations?'],
            [:wiki,                     :HASH,   'Hash with language codes as keys and values are hashes with the following keys:', [
                [:description,      :STRING, 'Description of this tag.' ],
                [:image,            :STRING, 'Wiki page title of associated image.' ],
                [:width,            :INT,    'Width of image.' ],
                [:height,           :INT,    'Height of image.' ],
                [:mime,             :STRING, 'MIME type of image.' ],
                [:image_url,        :STRING, 'Image URL' ],
                [:thumb_url_prefix, :STRING, 'Prefix of thumbnail URL.' ],
                [:thumb_url_suffix, :STRING, 'Suffix of thumbnail URL.' ]
            ]]
        ]),
        :notes => 'You have to either use the <tt>key</tt> parameter or the <tt>tags</tt> parameter.',
        :example => { :tags => 'highway=primary,secondary,amenity=post_box' }
    }) do
        pkey = params[:key]
        tags = nil

        if params[:tags].nil?
            tags = @db.execute("SELECT DISTINCT value FROM wikipages WHERE key=? AND value IS NOT NULL AND type='page' ORDER BY value", pkey).map{ |row| [ pkey, row['value'] ] }
        else
            last_key = nil
            tags = params[:tags].split(',').map{ |tag|
                kv = tag.split('=', 2)
                if kv.size == 1
                    kv = [last_key, kv]
                end
                last_key = kv[0]
                kv
            }
        end

        res = []
        tags.each do |key, value|
            data = @db.get_first_row("SELECT * FROM db.tags WHERE key=? AND value=?", key, value)

            if data
                if data['in_wiki']
                    wiki = @db.execute("SELECT * FROM wikipages LEFT OUTER JOIN wiki_images USING (image) WHERE key=? AND value=? ORDER BY lang", key, value)

                    data['wiki'] = {}
                    wiki.each do |w|
                        info = { 'description' => w['description'] }
                        unless w['image'].nil?
                            info['image'] = {}
                            %w(image width height mime image_url thumb_url_prefix thumb_url_suffix).each do |arg|
                                info['image'][arg] = w[arg]
                            end
                        end
                        data['wiki'][w['lang']] = info
                    end

                    wiki_default = wiki.select{ |w| w['lang'] == 'en' }[0] || wiki[0]
                    %w(on_node on_way on_area on_relation).each do |arg|
                        data[arg] = wiki_default[arg]
                    end
                end

                res << data
            end
        end

        return JSON.generate({
            :total => res.size,
            :url   => request.url,
            :data  => res.map{ |row| {
                :key                      => row['key'],
                :value                    => row['value'],
                :in_wiki                  => row['in_wiki'],
                :count_all                => row['count_all'].to_i,
                :count_all_fraction       => (row['count_all'].to_f / @db.stats('objects')).round_to(4),
                :count_nodes              => row['count_nodes'].to_i,
                :count_nodes_fraction     => (row['count_nodes'].to_f / @db.stats('nodes_with_tags')).round_to(4),
                :count_ways               => row['count_ways'].to_i,
                :count_ways_fraction      => (row['count_ways'].to_f / @db.stats('ways')).round_to(4),
                :count_relations          => row['count_relations'].to_i,
                :count_relations_fraction => (row['count_relations'].to_f / @db.stats('relations')).round_to(4),
                :wiki                     => row['wiki'],
                :on_node                  => row['on_node'].to_i     == 1,
                :on_way                   => row['on_way'].to_i      == 1,
                :on_area                  => row['on_area'].to_i     == 1,
                :on_relation              => row['on_relation'].to_i == 1,
            } }
        }, json_opts(params[:format]))
    end

    api(4, 'tags/popular', {
        :description => 'Get list of most often used tags.',
        :parameters => { :query => 'Only show tags matching this query (substring match in key and value, optional).' },
        :paging => :optional,
        :sort => %w( tag count_all count_nodes count_ways count_relations ),
        :result => paging_results([
            [:key,                      :STRING, 'Key'],
            [:value,                    :STRING, 'Value'],
            [:in_wiki,                  :BOOL,   'In there a page in the wiki for this tag?'],
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

        total = @db.count('top_tags').
            condition_if("(skey LIKE ? ESCAPE '@') OR (svalue LIKE ? ESCAPE '@')", like_contains(params[:query]), like_contains(params[:query])).
            get_first_value().to_i

        res = @db.select('SELECT * FROM top_tags').
            condition_if("(skey LIKE ? ESCAPE '@') OR (svalue LIKE ? ESCAPE '@')", like_contains(params[:query]), like_contains(params[:query])).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.tag :skey
                o.tag :svalue
                o.in_wiki
                o.count_all
                o.count_nodes
                o.count_ways
                o.count_relations
            }.
            paging(@ap).
            execute()

        return JSON.generate({
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :url   => request.url,
            :data  => res.map{ |row| {
                :key                      => row['skey'],
                :value                    => row['svalue'],
                :in_wiki                  => row['in_wiki'],
                :count_all                => row['count_all'].to_i,
                :count_all_fraction       => (row['count_all'].to_f / @db.stats('objects')).round_to(4),
                :count_nodes              => row['count_nodes'].to_i,
                :count_nodes_fraction     => (row['count_nodes'].to_f / @db.stats('nodes_with_tags')).round_to(4),
                :count_ways               => row['count_ways'].to_i,
                :count_ways_fraction      => (row['count_ways'].to_f / @db.stats('ways')).round_to(4),
                :count_relations          => row['count_relations'].to_i,
                :count_relations_fraction => (row['count_relations'].to_f / @db.stats('relations')).round_to(4),
            } }
        }, json_opts(params[:format]))
    end

end
