# web/lib/api/v4/langtag.rb
class Taginfo < Sinatra::Base

    api(0, 'keys/name', {
        :description => 'Get list of keys from the database that contain the string "name".',
        :parameters => { :query => 'Only show keys matching this query (substring match, optional).' },
        :paging => :optional,
        :sort => %w[ key count_all ],
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
            get_first_value.to_i

        res = @db.select('SELECT * FROM db.keys').
            condition("key LIKE '%name%'").
            condition_if("key LIKE '%' || ? || '%'", params[:query]).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.key
                o.count_all
            end.
            paging(@ap).
            execute

        return JSON.generate({
            :page  => @ap.page,
            :rp    => @ap.results_per_page,
            :total => total,
            :data  => res.map do |row|
                          nt = BCP47::Nametag.new(@db, row['key'])
                          {
                          :key           => row['key'],
                          :count_all     => row['count_all'].to_i,
                          :in_wiki       => row['in_wiki'].to_i != 0,
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
                      }
                      end
        }, json_opts(params[:format]))
    end

end
