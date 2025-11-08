function page_init() {
    widgetManager.addWidget(createDynamicTable('grid-errors', {
        url: '/api/4/wikidata/errors',
        colModel: [
            { display: h(texts.pages.sources.wikidata.errors.columns.item), name: 'item', width: 360, sortable: true },
            { display: h(texts.pages.sources.wikidata.errors.columns.property), name: 'property', width: 60, sortable: false },
            { display: h(texts.pages.sources.wikidata.errors.columns.propvalue), name: 'propvalue', width: 240, sortable: false },
            { display: h(texts.pages.sources.wikidata.errors.columns.error), name: 'error', width: 400, sortable: false }
        ],
        sortname: 'item',
        sortorder: 'asc',
        processRow: function(row) {
            return [
                fmt_wikidata_item(row.item, row.description),
                row.property,
                row.propvalue,
                row.error,
            ];
        }
    }));
}
