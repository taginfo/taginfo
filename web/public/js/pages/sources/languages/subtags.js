function createTable(filter_type) {
    return createDynamicTable('grid-subtags', {
        url: '/api/4/languages',
        params: { filter: filter_type },
        colModel: [
            { display: h(texts.pages.sources.languages.subtags.columns.type),        name: 'type',        width:  80 },
            { display: h(texts.pages.sources.languages.subtags.columns.subtag),      name: 'subtag',      width:  80, sortable: true },
            { display: h(texts.pages.sources.languages.subtags.columns.description), name: 'description', width: 500, sortable: true },
            { display: h(texts.pages.sources.languages.subtags.columns.added),       name: 'added',       width:  80, sortable: true },
            { display: h(texts.pages.sources.languages.subtags.columns.notes),       name: 'notes',       width: 400 }
        ],
        searchitems: [
            { display: 'Subtag or description', name: 'text' }
        ],
        sortname: 'subtag',
        sortorder: 'asc',
        processRow: row => {
            return [
                row.type,
                tag('tt', row.subtag),
                row.description,
                row.added,
                row.notes
            ];
        }
    });
}

function page_init() {
    up = function() { window.location = build_link('/sources/languages'); };
    const filter = document.getElementById('subtag-filter');
    const theTable = createTable(filter.value);
    widgetManager.addWidget(theTable);
    filter.addEventListener('change', function(element) {
        window.location.search = new URLSearchParams({ 'filter': element.target.value });
        theTable.load();
    });
}
