# web/lib/ui/compare.rb
class Taginfo < Sinatra::Base

    get %r{/compare/(.*)} do |items|
        @data = []

        # syntax is key=value@instance
        items&.split('/')&.each do |item|
            ti = item.split('@')
            kv = ti[0].split('=')
            instance = ''
            if ti.length > 1
                instance = ti[1]
            end
            @data << { :instance => instance, :key => kv[0], :value => kv[1] }
        end

        if params[:key].is_a?(Array)
            params[:key].each_with_index do |key, index|
                @data << {
                    :instance => params[:instance][index],
                    :key => key,
                    :value => (params[:value].is_a?(Array) ? (params[:value][index] == '' ? nil : params[:value][index]) : nil)
                }
            end
        end

        @data = @data[0..4] # allow to compare maximum of 5 items

        @data = @data.map do |data|
            key   = data[:key]
            value = data[:value]

            if value.nil?
                data.delete(:value)
                result = @db.select("SELECT count_all FROM db.keys").condition('key = ?', key).get_first_row
                if result
                    data[:has_map] = result['count_all'].to_i > 0
                    data
                end
            else
                data[:has_map] = (@db.count('tag_distributions').condition('key=? AND value=?', key, value).get_first_i > 0)
                data
            end
        end.compact

        @img_width  = (@taginfo_config.get('geodistribution.width')  * @taginfo_config.get('geodistribution.scale_compare_image')).to_i
        @img_height = (@taginfo_config.get('geodistribution.height') * @taginfo_config.get('geodistribution.scale_compare_image')).to_i

        javascript "pages/compare"
        erb :compare
    end

end
