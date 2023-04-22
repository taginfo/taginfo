# web/lib/api/v4/languages.rb
class Taginfo < Sinatra::Base

    @@bcp47_filters = {}
    BCP47::SUBTAG_TYPES.each do |type|
        @@bcp47_filters[type.to_sym] = { :expr => type, :doc => "Show entries of type '#{type}' only." }
    end

    api(4, 'languages', {
        :description => 'Get official subtags from the IETF BCP47 registry.',
        :parameters => { :query => 'Only show entries matching this query (case insensitive substring match on subtags and description; optional).' },
        :paging => :optional,
        :filter => @@bcp47_filters,
        :sort => %w[ subtag description added ],
        :result => {
            :type        => :STRING,
            :subtag      => :STRING,
            :description => :STRING,
            :added       => :STRING,
            :notes       => :STRING
        },
        :example => { :page => 1, :rp => 10, :sortname => :subtag, :sortorder => 'asc' },
        :ui => '/sources/languages/subtags'
    }) do
        @filter_type = BCP47.get_filter(params[:filter])

        total = @db.count('languages.subtags').
                condition_if('stype = ?', @filter_type).
                condition_if("subtag LIKE '%' || ? || '%' OR description LIKE '%' || ? || '%'", params[:query], params[:query]).
                get_first_value.to_i

        res = @db.select('SELECT * FROM languages.subtags').
            condition_if('stype = ?', @filter_type).
            condition_if("subtag LIKE '%' || ? || '%' OR description LIKE '%' || ? || '%'", params[:query], params[:query]).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.subtag
                o.description
                o.added
            end.
            paging(@ap).
            execute

        return JSON.generate({
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map do |row|
                notes = ''
                if row['suppress_script']
                    notes += "Default script: #{ row['suppress_script'] }"
                end
                unless row['prefix'].empty?
                    notes += "Prefixes: #{ row['prefix'] }"
                end
                {
                :type        => row['stype'].titlecase,
                :subtag      => row['subtag'],
                :description => row['description'],
                :added       => row['added'],
                :notes       => notes
                }
            end
        }, json_opts(params[:format]))
    end

end
