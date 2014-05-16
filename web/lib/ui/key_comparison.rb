# web/lib/ui/key_comparison.rb
class Taginfo < Sinatra::Base

    get %r{^/key_comparison/} do
        @keys = params[:key][0..5] # allow to compare maximum of 5 keys

        @count_all = []
        @count_nodes = []
        @count_ways = []
        @count_relations = []
        @desc = []
        @prevalent_values = []
        @wiki_pages = []

        @keys.each_with_index do |key, num|
            @count_all << @db.select("SELECT count_all FROM db.keys").condition('key = ?', key).get_first_value().to_i
            @count_nodes << @db.select("SELECT count_nodes FROM db.keys").condition('key = ?', key).get_first_value().to_i
            @count_ways << @db.select("SELECT count_ways FROM db.keys").condition('key = ?', key).get_first_value().to_i
            @count_relations << @db.select("SELECT count_relations FROM db.keys").condition('key = ?', key).get_first_value().to_i

            desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang=? AND key=? AND value IS NULL", r18n.locale.code, key).get_first_value())
            desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value IS NULL", key).get_first_value()) if desc == ''
            @desc << desc

            prevalent_values = @db.select("SELECT value, count, fraction FROM db.prevalent_values").
                condition('key=?', key).
                order_by([:count], 'DESC').
                execute().map{ |row| { 'value' => row['value'], 'count' => row['count'].to_i, 'fraction' => row['fraction'].to_f } }
            @prevalent_values << prevalent_values

            wiki_pages = @db.select("SELECT DISTINCT lang FROM wiki.wikipages WHERE key=? AND value IS NULL ORDER BY lang", key).
                execute().map{ |row| row['lang'] }
            @wiki_pages << wiki_pages

        end

        @img_width  = TaginfoConfig.get('geodistribution.width')
        @img_height = TaginfoConfig.get('geodistribution.height')

        javascript "#{ r18n.locale.code }/key_comparison"
        erb :key_comparison
    end

end

