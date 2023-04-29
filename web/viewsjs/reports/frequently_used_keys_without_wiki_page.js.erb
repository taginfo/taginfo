function createTable(english) {
    const theTable = createDynamicTable('grid-keys', {
        url: '/api/4/keys/without_wiki_page',
        params: { english: english },
        colModel: [
            { display: h(texts.reports.frequently_used_keys_without_wiki_page.table.create_wiki_page), name: 'create_wiki_page', width: 200 },
            { display: h(texts.osm.key), name: 'key', width: 180, sortable: true },
            { display: '<img src="/img/types/all.svg" width="16" height="16" alt=""/> ' + h(texts.osm.objects), name: 'count_all', width: 70, sortable: true, align: 'right', title: h(texts.misc.objects_tooltip) },
            { display: h(texts.osm.users), name: 'users_all', width: 44, sortable: true, align: 'right' },
            { display: h(texts.osm.values), name: 'values_all', width: 70, sortable: true, align: 'right', title: h(texts.misc.values_tooltip) },
            { display: h(texts.misc.prevalent_values), name: 'prevalent_values', width: 500, title: h(texts.misc.prevalent_values_tooltip) }
        ],
        searchitems: [
            { display: h(texts.osm.key), name: 'key' }
        ],
        sortname: 'count_all',
        sortorder: 'desc',
        processRow: row => {
            const key = new TaginfoKey(row.key);
            const wikiPage = new TaginfoWikiPage('Key:' + row.key);
            return [
                hover_expand(wikiPage.link({ edit: true })),
                hover_expand(key.link()),
                fmt_with_ts(row.count_all),
                fmt_with_ts(row.users_all),
                fmt_with_ts(row.values_all),
                fmt_prevalent_value_list(key, row.prevalent_values)
            ];
        }
    });
    widgetManager.addWidget(theTable);
    return theTable;
}

function english() {
    return document.getElementById('english').checked ? '1' : '0';
}

function page_init() {
    up = function() { window.location = build_link('/reports'); };
    const theTable = createTable(english());
    document.getElementById('english').addEventListener('click', () => {
        theTable.config.params.english = english();
        theTable.load();
    });
}
