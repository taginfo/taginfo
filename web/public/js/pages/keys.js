function page_init() {
    widgetManager.addWidget(createDynamicTable('grid-keys', {
        url: '/api/4/keys/all',
        params: { include: 'prevalent_values' },
        colModel: [
            { display: h(texts.osm.key), name: 'key', width: 160, sortable: true },
            { display: '<img src="/img/types/all.svg" width="16" height="16" alt=""/> ' + h(texts.osm.objects), name: 'count_all', width: 160, sortable: true, align: 'center', title: h(texts.misc.objects_tooltip) },
            { display: '<img src="/img/types/node.svg" width="16" height="16" alt=""/> ' + h(texts.osm.nodes), name: 'count_nodes', width: 250, sortable: true, align: 'center', title: h(texts.misc.nodes_tooltip) },
            { display: '<img src="/img/types/way.svg" width="16" height="16" alt=""/> ' + h(texts.osm.ways), name: 'count_ways', width: 250, sortable: true, align: 'center', title: h(texts.misc.ways_tooltip) },
            { display: '<img src="/img/types/relation.svg" width="16" height="16" alt=""/> ' + h(texts.osm.relations), name: 'count_relations',  width: 250, sortable: true, align: 'center', title: h(texts.misc.relations_tooltip) },
            { display: h(texts.osm.users), name: 'users_all', width: 44, sortable: true, align: 'right', title: h(texts.misc.users_tooltip) },
            { display: h(texts.taginfo.wiki), name: 'in_wiki', width: 25, sortable: true, align: 'center', title: h(texts.misc.in_wiki_tooltip) },
            { display: h(texts.taginfo.projects), name: 'projects', width: 40, sortable: true, align: 'right' },
            { display: h(texts.osm.values), name: 'values_all', width: 70, sortable: true, align: 'right', title: h(texts.misc.values_tooltip) },
            { display: h(texts.misc.prevalent_values), name: 'prevalent_values', width: 200, title: h(texts.misc.prevalent_values_tooltip) }
        ],
        searchitems: [
            { display: h(texts.osm.key), name: 'key' }
        ],
        sortname: 'count_all',
        sortorder: 'desc',
        processRow: row => {
            const key = new TaginfoKey(row.key);
            return [
                hover_expand(key.link()),
                fmt_value_with_percent(row.count_all,       row.count_all_fraction),
                fmt_value_with_percent(row.count_nodes,     row.count_nodes_fraction),
                fmt_value_with_percent(row.count_ways,      row.count_ways_fraction),
                fmt_value_with_percent(row.count_relations, row.count_relations_fraction),
                fmt_with_ts(row.users_all),
                key.link({tab: 'wiki', content: fmt_checkmark(row.in_wiki)}),
                key.link({tab: 'projects', content: html_escape(row.projects)}),
                fmt_with_ts(row.values_all),
                fmt_prevalent_value_list(key, row.prevalent_values)
            ];
        }
    }));
}
