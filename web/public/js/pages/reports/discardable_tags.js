function page_init() {
    widgetManager.addWidget(createDynamicTable('grid-tags', {
        url: '/api/4/keys/discardable',
        csv: true,
        colModel: [
            { display: h(texts.osm.key), name: 'key', width: 180, sortable: true },
            { display: h(texts.taginfo.wiki), name: 'wiki', align: 'center', width: 30, sortable: true },
            { display: 'iD', name: 'id', align: 'center', width: 30, sortable: true },
            { display: 'JOSM', name: 'josm', align: 'center', width: 30, sortable: true },
            { display: h(texts.misc.count), name: 'count_all', width: 50, sortable: true }
        ],
        sortname: 'key',
        sortorder: 'asc',
        processRow: row => {
            const key = new TaginfoKey(row.key);
            return [
                hover_expand(key.link()),
                key.link({tab: 'wiki', content: fmt_checkmark(row.wiki)}),
                fmt_checkmark(row.id),
                fmt_checkmark(row.josm),
                '<div style="width: 5em; text-align: right;">' + fmt_with_ts(row.count_all) + '</div>'
            ];
        }
    }));
}
