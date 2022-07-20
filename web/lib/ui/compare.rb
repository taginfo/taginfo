# web/lib/ui/compare.rb
class Taginfo < Sinatra::Base

    get %r{/compare/(.*)} do |items|
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
                result = @db.select("SELECT count_all FROM db.keys").condition('key = ?', key).get_first_row()
                if result
                    desc = get_key_description(key)
                    data[:desc]            = h(desc[0])
                    data[:lang]            = desc[1]
                    data[:dir]             = desc[2]

                    data[:has_map] = result['count_all'].to_i > 0
                    data
                else
                    nil
                end
            else
                desc = get_tag_description(key, value)
                data[:desc]            = h(desc[0])
                data[:lang]            = desc[1]
                data[:dir]             = desc[2]

                data[:has_map] = (@db.count('tag_distributions').condition('key=? AND value=?', key, value).get_first_i > 0)
                data
            end
        }.compact

        @img_width  = (@taginfo_config.get('geodistribution.width')  * @taginfo_config.get('geodistribution.scale_compare_image')).to_i
        @img_height = (@taginfo_config.get('geodistribution.height') * @taginfo_config.get('geodistribution.scale_compare_image')).to_i

        javascript "#{ r18n.locale.code }/compare"
        erb :compare
    end

end

