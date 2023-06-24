# web/lib/api/v4/relations.rb
class Taginfo < Sinatra::Base

    api(4, 'relations/all', {
        :description => 'Information about the different relation types.',
        :parameters => {
            :query => 'Only show results where the relation type matches this query (substring match, optional).'
        },
        :paging => :optional,
        :sort => %w[ rtype count ],
        :result => paging_results([
            [:rtype,           :STRING, 'Relation type'],
            [:count,           :INT,    'Number of relations with this type.'],
            [:count_fraction,  :INT,    'Number of relations with this type divided by the overall number of relations.'],
            [:prevalent_roles, :ARRAY,  'Prevalent member roles.', [
                [:role,     :STRING, 'Member role'],
                [:count,    :INT,    'Number of members with this role.'],
                [:fraction, :FLOAT,  'Number of members with this role divided by all members.']
            ]]
        ]),
        :notes => "prevalent_roles can be null if taginfo doesn't have role information for this relation type, or an empty array when there are no roles with more than 1% of members",
        :example => { :page => 1, :rp => 10 },
        :ui => '/relations'
    }) do
        total = @db.count('relation_types').
            condition_if("rtype LIKE ? ESCAPE '@'", like_contains(params[:query])).
            get_first_i

        res = @db.select('SELECT * FROM relation_types').
            condition_if("rtype LIKE ? ESCAPE '@'", like_contains(params[:query])).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.rtype
                o.count
            end.
            paging(@ap).
            execute

        all_relations = @db.stats('relations').to_i

        prevroles = @db.select('SELECT rtype, role, count, fraction FROM db.prevalent_roles').
            condition("rtype IN (#{ res.map{ |row| "'" + SQLite3::Database.quote(row['rtype']) + "'" }.join(',') })").
            order_by([:count], 'DESC').
            execute

        pr = {}
        res.each do |row|
            pr[row['rtype']] = []
        end

        prevroles.each do |pv|
            rtype = pv['rtype']
            pv.delete_if{ |k,v| k.is_a?(Integer) || k == 'rtype' }
            pv['count'] = pv['count'].to_i
            pv['fraction'] = pv['fraction'].to_f
            pr[rtype] << pv
        end

        return generate_json_result(total,
            res.map do |row| {
                :rtype           => row['rtype'],
                :count           => row['count'].to_i,
                :count_fraction  => row['count'].to_f / all_relations,
                :prevalent_roles => row['members_all'] ? pr[row['rtype']][0,10] : nil
            }
            end
        )
    end

end
