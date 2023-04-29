function page_init() {
    up = function() { window.location = build_link('/reports'); };
    widgetManager.addWidget(createDynamicTable('grid-keys', {
        url: '/api/4/keys/all',
        params: { filter: 'in_wiki,not_in_db', include: 'wikipages' },
        colModel: [
            { display: h(texts.osm.key), name: 'key', width: 250, sortable: true },
            { display: h(texts.reports.wiki_pages_about_non_existing_keys.wiki_pages), name: 'wikipages', width: 600 }
        ],
        searchitems: [
            { display: h(texts.osm.key), name: 'key' }
        ],
        sortname: 'count_all',
        sortorder: 'desc',
        processRow: row => {
            let wikilinks = [];
            for (wikipage of row.wikipages) {
                const wikiPage = new TaginfoWikiPage(wikipage.title);
                let w = wikiPage.link();
                if (wikipage.type == 'redirect') {
                    w += ' (REDIRECT)';
                }
                wikilinks.push(w);
            }
            const key = new TaginfoKey(row.key);
            return [
                hover_expand(key.link()),
                wikilinks.join(' &nbsp;&bull;&nbsp; ')
            ];
        }
    }));
}
