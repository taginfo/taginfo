# web/lib/api/langtag.rb
class Taginfo < Sinatra::Base

    api(2, 'langtag/name', {
        :description => 'Get list of keys from the database that contain the string "name".',
        :parameters => { :query => 'Only show keys matching this query (substring match, optional).' },
        :paging => :optional,
        :sort => %w( key count_all ),
        :result => {
            :key       => :STRING, 
            :count_all => :INT
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
            order_by(params[:sortname], params[:sortorder]) { |o|
                o.key
                o.count_all
            }.
            paging(params[:rp], params[:page]).
            execute()

        return {
            :page  => params[:page].to_i,
            :rp    => params[:rp].to_i,
            :total => total,
            :data  => res.map{ |row| {
                :key       => row['key'],
                :count_all => row['count_all'].to_i
            }} 
        }.to_json
    end

    @@bcp47_filters = {};
    BCP47::SUBTAG_TYPES.each do |type|
        @@bcp47_filters[type.to_sym] = { :expr => type, :doc => "Show entries of type '#{type}' only." };
    end

    api(2, 'langtag/bcp47', {
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

        if params[:sortname] =~ /^(subtag|description|added)$/
            s = params[:sortname].to_sym
            if params[:sortorder] == 'asc'
                entries.sort!{ |a, b| a.send(s) <=> b.send(s) }
            else
                entries.sort!{ |a, b| b.send(s) <=> a.send(s) }
            end
        end

        if params[:page]
            start = (params[:page].to_i - 1) * params[:rp].to_i
            entries = entries[start, params[:rp].to_i]
        end

        return {
            :page  => params[:page].to_i,
            :rp    => params[:rp].to_i,
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

