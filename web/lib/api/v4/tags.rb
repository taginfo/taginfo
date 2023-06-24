# web/lib/api/v4/tags.rb

def add_image_data(images, data, image_type)
    unless data[image_type].nil?
        data_title = data[image_type]['image']
        if images[data_title] != 1
            %w[ width height mime image_url thumb_url_prefix thumb_url_suffix ].each do |arg|
                data[image_type][arg] = images[data_title][arg]
            end
        end
    end
end

class Taginfo < Sinatra::Base

    api(4, 'tags/list', {
        :description => 'Get information on given tags or all tags documented on the wiki with given key.',
        :parameters => { :key => 'Key (optional)', :tags => 'Comma-separated list of tags in format key1=value1a,value1b,...,key2=value2a,value2b,... (optional).' },
        :paging => :no,
        :result => no_paging_results([
            [:key,                      :STRING, 'Key'],
            [:value,                    :STRING, 'Value'],
            [:in_wiki,                  :BOOL,   'In there at least one wiki page for this tag?'],
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
                [:description,          :STRING, 'Description of this tag.' ],
                [:image,                :HASH,   'Optional hash with information about descriptive image:', [
                    [:image,            :STRING, 'Wiki page title of associated image.' ],
                    [:width,            :INT,    'Width of image.' ],
                    [:height,           :INT,    'Height of image.' ],
                    [:mime,             :STRING, 'MIME type of image.' ],
                    [:image_url,        :STRING, 'Image URL' ],
                    [:thumb_url_prefix, :STRING, 'Prefix of thumbnail URL.' ],
                    [:thumb_url_suffix, :STRING, 'Suffix of thumbnail URL.' ]
                ]],
                [:osmcarto_rendering,   :HASH,   'Optional hash with information about default rendering:', [
                    [:image,            :STRING, 'Wiki page title of associated image.' ],
                    [:width,            :INT,    'Width of image.' ],
                    [:height,           :INT,    'Height of image.' ],
                    [:mime,             :STRING, 'MIME type of image.' ],
                    [:image_url,        :STRING, 'Image URL' ],
                    [:thumb_url_prefix, :STRING, 'Prefix of thumbnail URL.' ],
                    [:thumb_url_suffix, :STRING, 'Suffix of thumbnail URL.' ]
                ]]
            ]]
        ]),
        :notes => 'You have to either use the <tt>key</tt> parameter or the <tt>tags</tt> parameter.',
        :example => { :tags => 'highway=primary,secondary,amenity=post_box' }
    }) do
        pkey = params[:key]
        tags = nil

        if params[:tags].nil?
            tags = @db.execute("SELECT DISTINCT value FROM wiki.wikipages WHERE key=? AND value IS NOT NULL AND type='page' ORDER BY value", pkey).map{ |row| [ pkey, row['value'] ] }
        else
            last_key = nil
            tags = params[:tags].split(',').map do |tag|
                kv = tag.split('=', 2)
                if kv.size == 1
                    kv = [last_key, kv]
                end
                last_key = kv[0]
                kv
            end
        end

        res = []
        images = {}
        tags.each do |key, value|
            if value == '*'
                data = @db.get_first_row("SELECT * FROM db.keys WHERE key=?", key)

                if data
                    if data['in_wiki'].to_i != 0
                        wiki = @db.execute("SELECT * FROM wiki.wikipages WHERE key=? AND value IS NULL ORDER BY lang", key)
                        data['wiki'] = {}
                        wiki.each do |w|
                            info = { 'description' => w['description'] }
                            unless w['image'].nil?
                                images[w['image']] = 1
                                info['image'] = { 'image' => w['image'] }
                            end
                            data['wiki'][w['lang']] = info
                        end

                        wiki_default = wiki.select{ |w| w['lang'] == 'en' }[0] || wiki[0]
                        %w[ on_node on_way on_area on_relation ].each do |arg|
                            data[arg] = wiki_default[arg]
                        end
                    end

                    res << data
                end
            else
                data = @db.get_first_row("SELECT * FROM db.tags WHERE key=? AND value=?", key, value)

                if data
                    if data['in_wiki'].to_i != 0
                        wiki = @db.execute("SELECT * FROM wiki.wikipages WHERE key=? AND value=? ORDER BY lang", key, value)
                        data['wiki'] = {}
                        wiki.each do |w|
                            info = { 'description' => w['description'] }
                            unless w['image'].nil?
                                images[w['image']] = 1
                                info['image'] = { 'image' => w['image'] }
                            end
                            unless w['osmcarto_rendering'].nil?
                                images[w['osmcarto_rendering']] = 1
                                info['osmcarto_rendering'] = { 'image' => w['osmcarto_rendering'] }
                            end
                            data['wiki'][w['lang']] = info
                        end

                        wiki_default = wiki.select{ |w| w['lang'] == 'en' }[0] || wiki[0]
                        %w[ on_node on_way on_area on_relation ].each do |arg|
                            data[arg] = wiki_default[arg]
                        end
                    end

                    res << data
                end
            end
        end

        if images.size > 0
            image_list = @db.quote_and_join_array(images.keys)
            image_rows = @db.execute("SELECT * FROM wiki.wiki_images WHERE image IN (#{ image_list })")

            image_rows.each do |row|
                images[row['image']] = row
            end
        end

        res.each do |data|
            unless data['wiki'].nil?
                data['wiki'].each_value do |data_for_lang|
                    add_image_data(images, data_for_lang, 'image')
                    add_image_data(images, data_for_lang, 'osmcarto_rendering')
                end
            end
        end

        return generate_json_result(res.size,
            res.map do |row| {
                :key                      => row['key'],
                :value                    => row['value'],
                :in_wiki                  => row['in_wiki'],
                :count_all                => row['count_all'].to_i,
                :count_all_fraction       => (row['count_all'].to_f / @db.stats('objects')).round(4),
                :count_nodes              => row['count_nodes'].to_i,
                :count_nodes_fraction     => (row['count_nodes'].to_f / @db.stats('nodes_with_tags')).round(4),
                :count_ways               => row['count_ways'].to_i,
                :count_ways_fraction      => (row['count_ways'].to_f / @db.stats('ways')).round(4),
                :count_relations          => row['count_relations'].to_i,
                :count_relations_fraction => (row['count_relations'].to_f / @db.stats('relations')).round(4),
                :wiki                     => row['wiki'],
                :on_node                  => row['on_node'].to_i     == 1,
                :on_way                   => row['on_way'].to_i      == 1,
                :on_area                  => row['on_area'].to_i     == 1,
                :on_relation              => row['on_relation'].to_i == 1,
                :projects                 => row['projects'].to_i
            }
            end
        )
    end

    api(4, 'tags/popular', {
        :description => 'Get list of most often used tags.',
        :parameters => { :query => 'Only show tags matching this query (substring match in key and value, optional).' },
        :paging => :optional,
        :sort => %w[ tag count_all count_nodes count_ways count_relations ],
        :result => paging_results([
            [:key,                      :STRING, 'Key'],
            [:value,                    :STRING, 'Value'],
            [:in_wiki,                  :BOOL,   'In there at least one wiki page for this tag?'],
            [:count_all,                :INT,    'Number of objects in the OSM database with this tag.'],
            [:count_all_fraction,       :FLOAT,  'Number of objects in relation to all objects.'],
            [:count_nodes,              :INT,    'Number of nodes in the OSM database with this tag.'],
            [:count_nodes_fraction,     :FLOAT,  'Number of nodes in relation to all tagged nodes.'],
            [:count_ways,               :INT,    'Number of ways in the OSM database with this tag.'],
            [:count_ways_fraction,      :FLOAT,  'Number of ways in relation to all ways.'],
            [:count_relations,          :INT,    'Number of relations in the OSM database with this tag.'],
            [:count_relations_fraction, :FLOAT,  'Number of relations in relation to all relations.'],
            [:projects,                 :INT,    'Number of projects using this tag']
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'tag', :sortorder => 'asc' },
        :ui => '/tags'
    }) do

        total = @db.count('top_tags').
            condition_if("(skey LIKE ? ESCAPE '@') OR (svalue LIKE ? ESCAPE '@')", like_contains(params[:query]), like_contains(params[:query])).
            get_first_i

        res = @db.select('SELECT * FROM top_tags').
            condition_if("(skey LIKE ? ESCAPE '@') OR (svalue LIKE ? ESCAPE '@')", like_contains(params[:query]), like_contains(params[:query])).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.tag :skey
                o.tag :svalue
                o.in_wiki
                o.projects
                o.projects :skey
                o.count_all
                o.count_nodes
                o.count_ways
                o.count_relations
            end.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                :key                      => row['skey'],
                :value                    => row['svalue'],
                :in_wiki                  => row['in_wiki'],
                :count_all                => row['count_all'].to_i,
                :count_all_fraction       => (row['count_all'].to_f / @db.stats('objects')).round(4),
                :count_nodes              => row['count_nodes'].to_i,
                :count_nodes_fraction     => (row['count_nodes'].to_f / @db.stats('nodes_with_tags')).round(4),
                :count_ways               => row['count_ways'].to_i,
                :count_ways_fraction      => (row['count_ways'].to_f / @db.stats('ways')).round(4),
                :count_relations          => row['count_relations'].to_i,
                :count_relations_fraction => (row['count_relations'].to_f / @db.stats('relations')).round(4),
                :projects                 => row['projects'].to_i
            }
            end
        )
    end

end
