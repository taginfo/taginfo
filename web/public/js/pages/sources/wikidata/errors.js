function page_init() {
    widgetManager.addWidget(createDynamicTable('grid-errors', {
        url: '/api/4/wikidata/errors',
        colModel: [
            { display: h(texts.pages.sources.wikidata.errors.columns.item), name: 'item', width: 360, sortable: true },
            { display: h(texts.pages.sources.wikidata.errors.columns.p1282), name: 'p1282', width: 240, sortable: false },
            { display: h(texts.pages.sources.wikidata.errors.columns.error), name: 'error', width: 400, sortable: false }
        ],
        sortname: 'item',
        sortorder: 'asc',
        processRow: function(row) {
            return [
                fmt_wikidata_item(row.item, row.description),
                row.propvalue,
                row.error,
            ];
        }
    }));
}
