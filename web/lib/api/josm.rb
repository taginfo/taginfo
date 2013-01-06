# web/lib/api/josm.rb
class Taginfo < Sinatra::Base

    api(2, 'josm/styles/images', {
        :superseded_by => '4/josm/style/image',
        :description => 'Access images for map features used in JOSM.',
        :parameters => { :style => 'JOSM style', :image => 'Image path' },
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

    api(2, 'josm/styles') do
        # XXX dummy function
        return [
            { :id => 'standard', :name => 'standard', :url => '' }
        ].to_json
    end

    def get_josm_result(total, res)
        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map{ |row| {
                :k => row['k'],
                :v => row['v'],
                :b => row['b'],
                :rule => h(row['rule']),
                :area_color => row['area_color'] ? h(row['area_color'].sub(/^.*#/, '#')) : '',
                :line_color => row['line_color'] ? h(row['line_color'].sub(/^.*#/, '#')) : '',
                :line_width => row['line_width'] ? h(row['line_width']) : 0,
                :icon => row['icon_source'] && row['icon_source'] != 'misc/deprecated.png' && row['icon_source'] != 'misc/no_icon.png' ? h(row['icon_source']) : ''
            } }
        }.to_json
    end

    api(2, 'josm/styles/:style') do
        total = @db.count('josm_style_rules').
            condition_if("k LIKE '%' || ? || '%' OR v LIKE '%' || ? || '%'", params[:query], params[:query]).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
            condition_if("k LIKE '%' || ? || '%' OR v LIKE '%' || ? || '%'", params[:query], params[:query]).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.k :k
                o.k :v
                o.k :b
                o.v :v
                o.v :b
                o.v :k
                o.b
            }.
            paging(@ap).
            execute()

        return get_josm_result(total, res);
    end

    api(2, 'josm/styles/:style/keys') do
        style = params[:style] # XXX do something with this
        key   = params[:key]
        
        total = @db.count('josm_style_rules').
            condition('k = ?', key).
            condition_if("v LIKE '%' || ? || '%'", params[:query]).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
            condition('k = ?', key).
            condition_if("v LIKE '%' || ? || '%'", params[:query]).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.v :v
                o.v :b
                o.b
            }.
            paging(@ap).
            execute()

        return get_josm_result(total, res);
    end

    api(2, 'josm/styles/:style/tags') do
        key   = params[:key]
        value = params[:value]

        total = @db.count('josm_style_rules').
            condition('k = ?', key).
            condition('v = ?', value).
            get_first_value().to_i

        res = @db.select('SELECT * FROM josm_style_rules').
            condition('k = ?', key).
            condition('v = ?', value).
            order_by([:k, :v], 'ASC').
            paging(@ap).
            execute()

        return get_josm_result(total, res);
    end

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
            :b          => :STRING,
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
