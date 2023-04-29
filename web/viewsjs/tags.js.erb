function page_init() {
    widgetManager.addWidget(createDynamicTable('grid-tags', {
        url: '/api/4/tags/popular',
        colModel: [
            { display: h(texts.osm.tag), name: 'tag', width: 300, sortable: true },
            { display: '<img src="/img/types/all.svg" width="16" height="16" alt=""/> ' + h(texts.osm.objects), name: 'count_all', width: 220, sortable: true, align: 'center', title: h(texts.misc.objects_tooltip) },
            { display: '<img src="/img/types/node.svg" width="16" height="16" alt=""/> ' + h(texts.osm.nodes), name: 'count_nodes', width: 220, sortable: true, align: 'center', title: h(texts.misc.nodes_tooltip) },
            { display: '<img src="/img/types/way.svg" width="16" height="16" alt=""/> ' + h(texts.osm.ways), name: 'count_ways', width: 220, sortable: true, align: 'center', title: h(texts.misc.ways_tooltip) },
            { display: '<img src="/img/types/relation.svg" width="16" height="16" alt=""/> ' + h(texts.osm.relations), name: 'count_relations',  width: 220, sortable: true, align: 'center', title: h(texts.misc.relations_tooltip) },
            { display: h(texts.taginfo.wiki), name: 'in_wiki', width: 25, sortable: true, align: 'center', title: h(texts.misc.in_wiki_tooltip) },
            { display: h(texts.taginfo.projects), name: 'projects', width: 40, sortable: true, align: 'right' }
        ],
        searchitems: [
            { display: h(texts.osm.tag), name: 'tag' }
        ],
        sortname: 'count_all',
        sortorder: 'desc',
        processRow: row => {
            const tag = new TaginfoTag(row.key, row.value);
            return [
                hover_expand(tag.toKey().link() + '=' + tag.link({attrs: {'class': 'pref'}})),
                fmt_value_with_percent(row.count_all,       row.count_all_fraction),
                fmt_value_with_percent(row.count_nodes,     row.count_nodes_fraction),
                fmt_value_with_percent(row.count_ways,      row.count_ways_fraction),
                fmt_value_with_percent(row.count_relations, row.count_relations_fraction),
                tag.link({tab: 'wiki', content: fmt_checkmark(row.in_wiki)}),
                tag.link({tab: 'projects', content: html_escape(row.projects)}),
            ];
        }
    }));
}
