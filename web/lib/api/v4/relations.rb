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

    api(4, 'relations/roles', {
        :description => 'Show all roles and relation types.',
        :parameters => {
            :query => 'Only show results where the role matches this query (substring match, optional).'
        },
        :paging => :optional,
        :sort => %w[ role rtype count_all count_nodes count_ways count_relations ],
        :result => paging_results([
            [:role,            :STRING, 'Relation member role'],
            [:rtype,           :STRING, 'Relation type'],
            [:count_all,       :INT,    'Number of members with this relation type and role.'],
            [:count_nodes,     :INT,    'Number of members of type node with this relation type and role.'],
            [:count_ways,      :INT,    'Number of members of type way with this relation type and role.'],
            [:count_relations, :INT,    'Number of members of type relation with this relation type and role.'],
        ]),
        :example => { :page => 1, :rp => 10 },
        :ui => '/reports/roles'
    }) do
        total = @db.count('relation_roles').
            condition_if("role LIKE ? ESCAPE '@'", like_contains(params[:query])).
            get_first_i

        res = @db.select('SELECT * FROM relation_roles').
            condition_if("role LIKE ? ESCAPE '@'", like_contains(params[:query])).
            order_by(@ap.sortname, @ap.sortorder) do |o|
                o.role :role
                o.role! :count_all
                o.role :rtype
                o.rtype :rtype
                o.rtype! :count_all
                o.rtype :role
                o.count_all! :count_all
                o.count_all :role
                o.count_all :rtype
                o.count_nodes! :count_nodes
                o.count_nodes :role
                o.count_nodes :rtype
                o.count_ways! :count_ways
                o.count_ways :role
                o.count_ways :rtype
                o.count_relations! :count_relations
                o.count_relations :role
                o.count_relations :rtype
            end.
            paging(@ap).
            execute

        return generate_json_result(total,
            res.map do |row| {
                :role            => row['role'],
                :rtype           => row['rtype'],
                :count_all       => row['count_all'].to_i,
                :count_nodes     => row['count_nodes'].to_i,
                :count_ways      => row['count_ways'].to_i,
                :count_relations => row['count_relations'].to_i,
            }
            end
        )
    end

end
