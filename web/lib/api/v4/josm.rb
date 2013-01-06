# web/lib/api/v4/josm.rb
class Taginfo < Sinatra::Base

    api(4, 'josm/style/rules', {
        :description => 'List rules and symbols in JOSM styles.',
        :parameters => {
            :style => 'JOSM style (required).',
            :query => 'Only show results where the key or value matches this query (substring match, optional).'
        },
        :paging => :optional,
        :result => {
            :key        => :STRING,
            :value      => :STRING,
            :value_bool => :STRING,
            :rule       => :STRING,
            :area_color => :STRING,
            :line_color => :STRING,
            :line_width => :INT,
            :icon       => :STRING
        },
        :example => { :style => 'standard', :page => 1, :rp => 10},
        :ui => '/reports/josm_styles'
    }) do
        style = params[:style]

        total = @db.count('josm_style_rules').
#            condition('style = ?', style).
            condition_if("k LIKE '%' || ? || '%' OR v LIKE '%' || ? || '%'", params[:query], params[:query]).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
#            condition('style = ?', style).
            condition_if("k LIKE '%' || ? || '%' OR v LIKE '%' || ? || '%'", params[:query], params[:query]).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.key :k
                o.key :v
                o.key :b
                o.value :v
                o.value :b
                o.value :k
                o.b
            }.
            paging(@ap).
            execute()

        return get_josm_style_rules_result(total, res);
    end

    api(4, 'josm/style/image', {
        :description => 'Access images for map features used in JOSM.',
        :parameters => {
            :style => 'JOSM style (required).',
            :image => 'Image path (required).'
        },
        :result => 'PNG image.',
        :example => { :style => 'standard', :image => 'transport/bus.png' },
        :ui => '/keys/landuse#josm'
    }) do
        style = params[:style]
        image = params[:image]
        content_type :png
        @db.select('SELECT png FROM josm.josm_style_images').
            condition('style = ?', style).
            condition('path = ?', image).
            get_first_value()
    end

end
