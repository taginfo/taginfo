# web/lib/api/v4/wikidata.rb
class Taginfo < Sinatra::Base

    api(4, 'wikidata/keys', {
        :description => 'Get all wikidata entries about keys.',
        :parameters => {
            :lang => "Language for description (optional, default: 'en').",
            :query => 'Only show results matching this string (substring match on key/item code/item description, optional).'
        },
        :paging => :optional,
        :sort => %w[ key item ],
        :result => paging_results([
            [:item,        :STRING, 'The wikidata items Q or P code.'],
            [:key,         :STRING, 'The OSM key.'],
            [:description, :STRING, 'The description of the wikidata item.'],
        ]),
        :example => { :lang => 'fr', :page => 1, :rp => 10, :sortname => 'item', :sortorder => 'asc' },
        :ui => '/sources/wikidata/keys'
    }) do
        language = params[:lang] || 'en'
        query = params[:query].to_s
        query_like = like_contains(query)

        cq = @db.count('wikidata.wikidata_keys d, wikidata.wikidata_labels l').
            condition('d.code = l.code').
            condition('l.lang = ?', language)

        if query != ''
            cq = cq.condition("(d.code LIKE ? ESCAPE '@') OR (d.key LIKE ? ESCAPE '@') OR (l.label LIKE ? ESCAPE '@')", query_like, query_like, query_like)
        end

        total = cq.get_first_i

        dq = @db.select("SELECT d.code, l.label, d.key FROM wikidata.wikidata_keys d, wikidata.wikidata_labels l").
            condition('d.code = l.code').
            condition('l.lang = ?', language)

        if query != ''
            dq = dq.condition("(d.code LIKE ? ESCAPE '@') OR (d.key LIKE ? ESCAPE '@') OR (l.label LIKE ? ESCAPE '@')", query_like, query_like, query_like)
        end

        res = dq.order_by(@ap.sortname, @ap.sortorder) { |o|
                o.type :propvalue
                o.key :key
                o.item "substr(d.code, 1, 1) || substr('00000000000000000000' || substr(d.code, 2), -20)"
            }.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row|
                {
                    :item => row['code'],
                    :key => row['key'],
                    :description => row['label']
                }
            end
        )
    end

    api(4, 'wikidata/tags', {
        :description => 'Get all wikidata entries about tags.',
        :parameters => {
            :lang => "Language for description (optional, default: 'en').",
            :query => 'Only show results matching this string (substring match on key/value/item code/item description, optional).'
        },
        :paging => :optional,
        :sort => %w[ tag item ],
        :result => paging_results([
            [:item,        :STRING, 'The wikidata items Q or P code.'],
            [:key,         :STRING, 'The OSM key.'],
            [:value,       :STRING, 'The OSM value.'],
            [:description, :STRING, 'The description of the wikidata item.'],
        ]),
        :example => { :lang => 'fr', :page => 1, :rp => 10, :sortname => 'item', :sortorder => 'asc' },
        :ui => '/sources/wikidata/tags'
    }) do
        language = params[:lang] || 'en'
        query = params[:query].to_s
        query_like = like_contains(query)

        cq = @db.count('wikidata.wikidata_tags d, wikidata.wikidata_labels l').
            condition('d.code = l.code').
            condition('l.lang = ?', language)

        if query != ''
            cq = cq.condition("(d.code LIKE ? ESCAPE '@') OR (d.key LIKE ? ESCAPE '@') OR (d.value LIKE ? ESCAPE '@') OR (l.label LIKE ? ESCAPE '@')", query_like, query_like, query_like, query_like)
        end

        total = cq.get_first_i

        dq = @db.select("SELECT d.code, l.label, d.key, d.value FROM wikidata.wikidata_tags d, wikidata.wikidata_labels l").
            condition('d.code = l.code').
            condition('l.lang = ?', language)

        if query != ''
            dq = dq.condition("(d.code LIKE ? ESCAPE '@') OR (d.key LIKE ? ESCAPE '@') OR (d.value LIKE ? ESCAPE '@') OR (l.label LIKE ? ESCAPE '@')", query_like, query_like, query_like, query_like)
        end

        res = dq.order_by(@ap.sortname, @ap.sortorder) { |o|
                o.type :propvalue
                o.tag :key
                o.tag :value
                o.item "substr(d.code, 1, 1) || substr('00000000000000000000' || substr(d.code, 2), -20)"
            }.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row|
                {
                    :item => row['code'],
                    :key => row['key'],
                    :value => row['value'],
                    :description => row['label']
                }
            end
        )
    end

    api(4, 'wikidata/errors', {
        :description => 'Get import errors for wikidata source.',
        :paging => :optional,
        :sort => %w[ item ],
        :result => paging_results([
            [:property,   :STRING, 'The property showing the error - P1282 (tag) or P13786 (key).'],
            [:item,       :STRING, 'The wikidata items Q or P code.'],
            [:propvalue,  :STRING, 'The wikidata item property value.'],
            [:desciption, :STRING, 'The description of the wikidata item.'],
            [:error,      :STRING, 'The error message.'],
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'item', :sortorder => 'asc' },
        :ui => '/sources/wikidata/errors'
    }) do
        total = @db.count('wikidata.wikidata_errors').get_first_i

        res = @db.select("SELECT d.wikidata, d.code, d.propvalue, d.description, d.error FROM wikidata.wikidata_errors d").
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.item "substr(d.code, 1, 1) || substr('00000000000000000000' || substr(d.code, 2), -20)"
            }.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map{ |row| {
                :item => row['code'],
                :property => row['wikidata'],
                :propvalue => row['propvalue'],
                :description => row['description'],
                :error => row['error']
            }}
        )
    end

end
