function fmt_prevalent_role_list(list) {
    if (list === null) {
        return empty(h(texts.pages.relations.no_information));
    }
    if (list.length == 0) {
        return empty(pages.relations.roles_less_than_one_percent);
    }
    return list.map(function(item) {
        let attrs = { 'data-tooltip-position': 'OnLeft' };
        let role;
        if (item.role) {
            attrs['title'] = html_escape(item.role) + ' (' + fmt_as_percent(item.fraction) + ')';
            role = fmt_role(item.role);
        } else {
            attrs['title'] = '(' + fmt_as_percent(item.fraction) + ')';
            role = empty(h(texts.pages.relations.empty_role));
        }
        return tag('span', role, attrs);
    }).join(' &bull; ');
}

const tabsConfig = {
    types: function() {
        return new DynamicTable('grid-relations', {
            url: '/api/4/relations/all',
            colModel: [
                { display: h(texts.osm.relation_type), name: 'rtype', width: 140, sortable: true },
                { display: h(texts.osm.relations), name: 'count', width: 220, sortable: true, align: 'center', title: h(texts.pages.relations.relations_of_type_tooltip) },
                { display: h(texts.osm.tag), name: 'tag', width: 140 },
                { display: h(texts.pages.relations.prevalent_roles), name: 'prevalent_roles', width: 200, title: h(texts.pages.relations.prevalent_roles_tooltip) }
            ],
            searchitems: [
                { display: h(texts.osm.relation_type), name: 'rtype' }
            ],
            sortname: 'count',
            sortorder: 'desc',
            processRow: row => {
                const relation = new TaginfoRelation(row.rtype);
                return [
                    hover_expand(relation.link()),
                    fmt_value_with_percent(row.count, row.count_fraction),
                    hover_expand(relation.toTag().link()),
                    fmt_prevalent_role_list(row.prevalent_roles)
                ];
            }
        });
    },
    roles: function() {
        return new DynamicTable('grid-roles', {
            url: '/api/4/relations/roles',
            colModel: [
                { display: h(texts.osm.relation_member_role), name: 'role', width: 200, sortable: true },
                { display: h(texts.osm.relation_members), name: 'count_all', width: 120, sortable: true, align: 'right' },
                { display: h(texts.osm.relation_member_nodes), name: 'count_nodes', width: 120, sortable: true, align: 'right' },
                { display: h(texts.osm.relation_member_ways), name: 'count_ways', width: 120, sortable: true, align: 'right' },
                { display: h(texts.osm.relation_member_relations), name: 'count_relations', width: 120, sortable: true, align: 'right' },
                { display: h(texts.osm.relation_type), name: 'rtype', width: 200, sortable: true },
            ],
            searchitems: [
                { display: h(texts.osm.relation_member_role), name: 'role' }
            ],
            sortname: 'role',
            sortorder: 'asc',
            processRow: row => {
                const relation = new TaginfoRelation(row.rtype);
                return [
                        fmt_role(row.role),
                        row.count_all,
                        row.count_nodes,
                        row.count_ways,
                        row.count_relations,
                        hover_expand(relation.link()),
                ];
            }
        });
    }
};

function page_init() {
    initTabs(tabsConfig);
};
