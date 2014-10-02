# web/lib/api/v4/josm.rb
class Taginfo < Sinatra::Base

    api(4, 'josm/style/image', {
        :superseded_by => '',
        :description => 'DEPRECATED. Access images for map features used in JOSM.',
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

    api(4, 'josm/style/rules', {
        :superseded_by => '',
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
        :example => { :style => 'standard', :page => 1, :rp => 10 },
        :ui => '/reports/josm_styles'
    }) do
        total = 0
        res = []
        return get_josm_style_rules_result(total, res);
    end

end
