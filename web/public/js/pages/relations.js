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

function page_init() {
    widgetManager.addWidget(createDynamicTable('grid-relations', {
        url: '/api/4/relations/all',
        colModel: [
            { display: h(texts.osm.relation_type), name: 'rtype', width: 220, sortable: true },
            { display: h(texts.osm.relations), name: 'count', width: 250, sortable: true, align: 'center', title: h(texts.pages.relations.relations_of_type_tooltip) },
            { display: h(texts.osm.tag), name: 'tag', width: 250 },
            { display: h(texts.pages.relations.prevalent_roles), name: 'prevalent_roles', width: 550, title: h(texts.pages.relations.prevalent_roles_tooltip) }
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
    }));
};
