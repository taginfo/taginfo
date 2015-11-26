# web/lib/ui/compare.rb
class Taginfo < Sinatra::Base

    get %r{^/compare/(.*)} do |items|
        @data = []

        if !items.nil?
            items.split('/').each do |item|
                kv = item.split('=')
                @data << { :key => kv[0], :value => kv[1] }
            end
        end

        if params[:key].is_a?(Array)
            params[:key].each_with_index do |key, index|
                @data << {
                    :key => key,
                    :value => (params[:value].is_a?(Array) ? (params[:value][index] == '' ? nil : params[:value][index]) : nil)
                }
            end
        end

        @data = @data[0..4] # allow to compare maximum of 5 items

        @data = @data.map{ |data|
            key   = data[:key]
            value = data[:value]

            if value.nil?
                result = @db.select("SELECT count_all, count_nodes, count_ways, count_relations FROM db.keys").condition('key = ?', key).get_first_row()
                if result
                    data[:count_all]       = result['count_all']
                    data[:count_nodes]     = result['count_nodes']
                    data[:count_ways]      = result['count_ways']
                    data[:count_relations] = result['count_relations']

                    desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang=? AND key=? AND value IS NULL", r18n.locale.code, key).get_first_value())
                    desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value IS NULL", key).get_first_value()) if desc == ''
                    data[:desc] = desc

                    prevalent_values = @db.select("SELECT value, count, fraction FROM db.prevalent_values").
                        condition('key=?', key).
                        order_by([:count], 'DESC').
                        execute().map{ |row| { 'value' => row['value'], 'count' => row['count'].to_i, 'fraction' => row['fraction'].to_f } }
                    data[:prevalent_values] = prevalent_values

                    data[:wiki_pages] = @db.select("SELECT DISTINCT lang FROM wiki.wikipages WHERE key=? AND value IS NULL ORDER BY lang", key).execute().map{ |row| row['lang'] }

                    data[:has_map] = data[:count_all] > 0
                    data
                else
                    nil
                end
            else
                result = @db.select("SELECT count_all, count_nodes, count_ways, count_relations FROM db.tags").condition('key=? AND value=?', key, value).get_first_row()
                if result
                    data[:count_all]       = result['count_all']
                    data[:count_nodes]     = result['count_nodes']
                    data[:count_ways]      = result['count_ways']
                    data[:count_relations] = result['count_relations']

                    desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang=? AND key=? AND value=?", r18n.locale.code, key, value).get_first_value())
                    desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value=?", key, value).get_first_value()) if desc == ''
                    data[:desc] = desc

                    data[:prevalent_values] = []

                    data[:wiki_pages] = @db.select("SELECT DISTINCT lang FROM wiki.wikipages WHERE key=? AND value=? ORDER BY lang", key, value).execute().map{ |row| row['lang'] }

                    data[:has_map] = (@db.count('tag_distributions').condition('key=? AND value=?', key, value).get_first_i > 0)
                    data
                else
                    nil
                end
            end
        }.compact

        @img_width  = (TaginfoConfig.get('geodistribution.width')  * TaginfoConfig.get('geodistribution.scale_compare_image')).to_i
        @img_height = (TaginfoConfig.get('geodistribution.height') * TaginfoConfig.get('geodistribution.scale_compare_image')).to_i

        javascript "#{ r18n.locale.code }/compare"
        erb :compare
    end

end

