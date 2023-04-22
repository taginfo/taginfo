function page_init() {
    up = function() { window.location = build_link('/sources/wikidata'); }

    widgetManager.addWidget(createDynamicTable('grid-items', {
        url: '/api/4/wikidata/all',
        params: { lang: context.lang },
        colModel: [
            { display: h(texts.pages.sources.wikidata.items.columns.type), name: 'type', width: 40, sortable: true },
            { display: h(texts.pages.sources.wikidata.items.columns.ktr), name: 'ktr', width: 260, sortable: true },
            { display: h(texts.pages.sources.wikidata.items.columns.item), name: 'item', width: 200, sortable: true },
        ],
        searchitems: [
            { display: h(texts.misc.all), name: 'all' }
        ],
        sortname: 'ktr',
        sortorder: 'asc',
        processRow: function(row) {
            let ktr = 'unknown';
            if (row.type == 'key') {
                ktr = (new TaginfoKey(row.key)).link();
            } else if (row.type == 'tag') {
                ktr = (new TaginfoTag(row.key, row.value)).fullLink();
            } else if (row.type == 'relation') {
                ktr = (new TaginfoRelation(row.rtype)).link();
            } else {
                'unknown'
            }
            return [
                row.type.charAt(0).toUpperCase() + row.type.slice(1),
                ktr,
                fmt_wikidata_item(row.item, row.description)
            ];
        }
    }));
}
