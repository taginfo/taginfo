# web/lib/api/v4/wikidata.rb
class Taginfo < Sinatra::Base

    api(4, 'wikidata/all', {
        :description => 'Get all wikidata entries about keys, tags, and relations.',
        :parameters => {
            :lang => "Language for description (optional, default: 'en').",
            :query => 'Only show results matching this string (substring match on key/value/rtype/item code/item description, optional).'
        },
        :paging => :optional,
        :sort => %w[ type ktr item ],
        :result => paging_results([
            [:type,        :STRING, "One of 'key', 'tag', or 'relation'."],
            [:item,        :STRING, 'The wikidata items Q or P code.'],
            [:description, :STRING, 'The description of the wikidata item.'],
            [:key,         :STRING, "The OSM key related to this item (set for key and 'tag' type)."],
            [:value,       :STRING, "The value of the OSM tag related to this item (set for 'tag' type)."],
            [:rtype,       :STRING, "The OSM relation type related to this item (set for 'relation' type)."],
        ]),
        :example => { :lang => 'fr', :page => 1, :rp => 10, :sortname => 'item', :sortorder => 'asc' },
        :ui => '/sources/wikidata/items'
    }) do
        language = params[:lang] || 'en'
        query = params[:query].to_s
        query_like = like_contains(query)

        cq = @db.count('wikidata.wikidata_p1282 d, wikidata.wikidata_labels l').
            condition('d.relation_role IS NULL').
            condition('d.code = l.code').
            condition('l.lang = ?', language)

        if query != ''
            cq = cq.condition("(d.code LIKE ? ESCAPE '@') OR (d.key LIKE ? ESCAPE '@') OR (d.value LIKE ? ESCAPE '@') OR (d.relation_type LIKE ? ESCAPE '@') OR (l.label LIKE ? ESCAPE '@')", query_like, query_like, query_like, query_like, query_like)
        end

        total = cq.get_first_i

        dq = @db.select("SELECT d.ptype, d.code, l.label, d.key, d.value, d.relation_type FROM wikidata.wikidata_p1282 d, wikidata.wikidata_labels l").
            condition('d.relation_role IS NULL').
            condition('d.code = l.code').
            condition('l.lang = ?', language)

        if query != ''
            dq = dq.condition("(d.code LIKE ? ESCAPE '@') OR (d.key LIKE ? ESCAPE '@') OR (d.value LIKE ? ESCAPE '@') OR (d.relation_type LIKE ? ESCAPE '@') OR (l.label LIKE ? ESCAPE '@')", query_like, query_like, query_like, query_like, query_like)
        end

        res = dq.order_by(@ap.sortname, @ap.sortorder) { |o|
                o.type :propvalue
                o.ktr "coalesce(d.key || d.value, d.key, 'type' || d.relation_type)"
                o.item "substr(d.code, 1, 1) || substr('00000000000000000000' || substr(d.code, 2), -20)"
            }.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row|
                r = {
                    :type => row['ptype'],
                    :item => row['code'],
                    :description => row['label']
                }
                if row['key']
                    r[:key] = row['key']
                end
                if row['value']
                    r[:value] = row['value']
                end
                if row['relation_type']
                    r[:rtype] = row['relation_type']
                end
                r
            end
        )
    end

    api(4, 'wikidata/errors', {
        :description => 'Get import errors for wikidata source.',
        :paging => :optional,
        :sort => %w[ item ],
        :result => paging_results([
            [:item,       :STRING, 'The wikidata items Q or P code.'],
            [:propvalue,  :STRING, 'The wikidata item property value.'],
            [:desciption, :STRING, 'The description of the wikidata item.'],
            [:error,      :STRING, 'The error message.'],
        ]),
        :example => { :page => 1, :rp => 10, :sortname => 'item', :sortorder => 'asc' },
        :ui => '/sources/wikidata/errors'
    }) do
        total = @db.count('wikidata.wikidata_p1282_errors').get_first_i

        res = @db.select("SELECT d.code, d.propvalue, d.description, d.error FROM wikidata.wikidata_p1282_errors d").
            order_by(@ap.sortname, @ap.sortorder) { |o|
                o.item "substr(d.code, 1, 1) || substr('00000000000000000000' || substr(d.code, 2), -20)"
            }.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map{ |row| {
                :item => row['code'],
                :propvalue => row['propvalue'],
                :description => row['description'],
                :error => row['error']
            }}
        )
    end

end
