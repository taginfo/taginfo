# web/lib/api/v4/langtag.rb
class Taginfo < Sinatra::Base

    api(4, 'keys/name', {
        :description => 'Get list of keys from the database that contain the string "name".',
        :parameters => { :query => 'Only show keys matching this query (substring match, optional).' },
        :paging => :optional,
        :sort => %w( key count_all ),
        :result => {
            :key           => :STRING, 
            :count_all     => :INT,
            :in_wiki       => :BOOL,
            :prefix        => :STRING,
            :type          => :STRING,
            :langtag       => :STRING,
            :langtag_state => :STRING,
            :lang          => :STRING,
            :lang_state    => :STRING,
            :lang_name     => :STRING,
            :script        => :STRING,
            :script_state  => :STRING,
            :region        => :STRING,
            :region_state  => :STRING,
            :notes         => :STRING
        },
        :example => { :page => 1, :rp => 10, :sortname => 'key', :sortorder => 'asc' },
        :ui => '/reports/name_tags'
    }) do

        total = @db.count('db.keys').
            condition("key LIKE '%name%'").
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            get_first_value().to_i
        
        res = @db.select('SELECT * FROM db.keys').
            condition("key LIKE '%name%'").
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.key
                o.count_all
            }.
            paging(@ap).
            execute()

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map{ |row|
                nt = BCP47::Nametag.new(row['key'])
                {
                :key           => row['key'],
                :count_all     => row['count_all'].to_i,
                :in_wiki       => row['in_wiki'].to_i == 1 ? true : false,
                :prefix        => nt.prefix,
                :type          => nt.type,
                :langtag       => nt.langtag,
                :langtag_state => nt.langtag_state,
                :lang          => nt.lang,
                :lang_state    => nt.lang_state,
                :lang_note     => nt.lang_note,
                :script        => nt.script,
                :script_state  => nt.script_state,
                :script_note   => nt.script_note,
                :region        => nt.region,
                :region_state  => nt.region_state,
                :region_note   => nt.region_note,
                :notes         => nt.notes
            }} 
        }.to_json
    end

    @@bcp47_filters = {};
    BCP47::SUBTAG_TYPES.each do |type|
        @@bcp47_filters[type.to_sym] = { :expr => type, :doc => "Show entries of type '#{type}' only." };
    end

    api(4, 'langtags', {
        :description => 'Get official subtags from the IETF BCP47 registry.',
        :parameters => { :query => 'Only show entries matching this query (case insensitive substring match on subtags and description; optional).' },
        :paging => :optional,
        :filter => @@bcp47_filters,
        :sort => %w( subtag description added ),
        :result => {
            :type        => :STRING,
            :subtag      => :STRING,
            :description => :STRING,
            :added       => :STRING,
            :notes       => :STRING
        },
        :example => { :page => 1, :rp => 10, :sortname => :subtag, :sortorder => 'asc' },
        :ui => '/reports/name_tags#bcp47'
    }) do

        @filter_type = BCP47.get_filter(params[:filter])

        entries = BCP47::Entry::entries(@filter_type) 

        if params[:query]
            q = params[:query].downcase
            entries = entries.select do |entry|
                !entry.subtag.downcase.index(q).nil? || !entry.description.downcase.index(q).nil?
            end
        end

        total = entries.size

        if @ap.sortname =~ /^(subtag|description|added)$/
            s = @ap.sortname.to_sym
            if @ap.sortorder == 'ASC'
                entries.sort!{ |a, b| a.send(s) <=> b.send(s) }
            else
                entries.sort!{ |a, b| b.send(s) <=> a.send(s) }
            end
        end

        if @ap.do_paging?
            entries = entries[@ap.first_result, @ap.results_per_page]
        end

        return {
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => entries.map{ |entry| h = {
                :type        => entry.type.titlecase,
                :subtag      => entry.subtag,
                :description => entry.description,
                :added       => entry.added,
                :notes       => entry.notes
            }}
        }.to_json
    end

end

