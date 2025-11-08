function page_init() {
    widgetManager.addWidget(createDynamicTable('grid-items', {
        url: '/api/4/wikidata/keys',
        params: { lang: context.lang },
        colModel: [
            { display: h(texts.osm.key), name: 'key', width: 200, sortable: true },
            { display: h(texts.pages.sources.wikidata.keys.columns.item), name: 'item', width: 200, sortable: true },
        ],
        searchitems: [
            { display: h(texts.misc.all), name: 'all' }
        ],
        sortname: 'key',
        sortorder: 'asc',
        processRow: function(row) {
            return [
                (new TaginfoKey(row.key)).link(),
                fmt_wikidata_item(row.item, row.description)
            ];
        }
    }));
}
