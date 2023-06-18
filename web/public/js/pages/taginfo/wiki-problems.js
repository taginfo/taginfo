const tabsConfig = {
    list: function() {
        return new DynamicTable('grid-wiki-problems', {
            url: '/api/0/wiki/problems',
            colModel: [
                { display: 'Location', name: 'location', width: 200, sortable: true },
                { display: 'Reason', name: 'reason', width: 240, sortable: true },
                { display: 'Wiki page', name: 'title', width: 180, sortable: true },
                { display: h(texts.misc.language), name: 'lang', width: 50, sortable: true },
                { display: h(texts.osm.tag), name: 'tag', width: 150, sortable: true },
                { display: 'Additional info', name: 'info', width: 240 },
            ],
            searchitems: [
                { display: 'Location/Reason/Wiki page', name: 'filter' }
            ],
            sortname: 'reason',
            sortorder: 'asc',
            processRow: row => {
                const wikiPage = new TaginfoWikiPage(row.title);
                return [
                    row.location,
                    row.reason,
                    wikiPage.link(),
                    row.reason == 'wrong lang format' ? '' : fmt_language(row.lang, 'auto', '', ''),
                    row.key === null ? '' : createKeyOrTag(row.key, row.value).fullLink({ with_asterisk: true }),
                    row.info
                ];
            }
        });
    }
};

function page_init() {
    initTabs(tabsConfig);
}
