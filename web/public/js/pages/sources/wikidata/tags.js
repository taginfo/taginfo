function page_init() {
    widgetManager.addWidget(createDynamicTable('grid-items', {
        url: '/api/4/wikidata/tags',
        params: { lang: context.lang },
        colModel: [
            { display: h(texts.osm.tag), name: 'tag', width: 200, sortable: true },
            { display: h(texts.pages.sources.wikidata.tags.columns.item), name: 'item', width: 200, sortable: true },
        ],
        searchitems: [
            { display: h(texts.misc.all), name: 'all' }
        ],
        sortname: 'tag',
        sortorder: 'asc',
        processRow: function(row) {
            return [
                (new TaginfoTag(row.key, row.value)).fullLink(),
                fmt_wikidata_item(row.item, row.description)
            ];
        }
    }));
}
