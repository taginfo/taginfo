# web/lib/api/v4/josm.rb
class Taginfo < Sinatra::Base

    api(4, 'josm/style/rules', {
        :description => 'List rules and symbols in JOSM styles.',
        :parameters => {
            :style => 'JOSM style (required).',
            :query => 'Only show results where the key or value matches this query (substring match, optional).'
        },
        :paging => :optional,
        :result => paging_results([
            [:key,        :STRING, 'Key'],
            [:value,      :STRING, 'Value'],
            [:value_bool, :STRING, '"yes" or "no". Null if the value is not boolean.'],
            [:rule,       :STRING, 'JOSM style rule in XML format.'],
            [:area_color, :STRING, 'Fill color for area (if area rule).'],
            [:line_color, :STRING, 'Stroke color for line (if line rule).'],
            [:line_width, :INT,    'Line width (if line rule).'],
            [:icon,       :STRING, 'Icon path (if icon rule).']
        ]),
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
