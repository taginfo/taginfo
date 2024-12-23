const tabsConfig = {
    list: function() {
        return new DynamicTable('grid-wiki-problems', {
            url: '/api/4/wiki/problems',
            colModel: [
                { display: h(texts.pages.sources.wiki.parsing_problems.wiki_page), name: 'title', width: 280, sortable: true },
                { display: h(texts.pages.sources.wiki.parsing_problems.location), name: 'location', width: 140, sortable: true },
                { display: h(texts.pages.sources.wiki.parsing_problems.reason), name: 'reason', width: 280, sortable: true },
                { display: h(texts.pages.sources.wiki.parsing_problems.lang), name: 'lang', width: 30, sortable: true },
                { display: h(texts.osm.tag), name: 'tag', width: 160, sortable: true },
                { display: h(texts.pages.sources.wiki.parsing_problems.info), name: 'info', width: 600 }
            ],
            searchitems: [
                { display: 'Location/Reason/Wiki page', name: 'filter' }
            ],
            sortname: 'reason',
            sortorder: 'asc',
            processRow: row => {
                const wikiPage = new TaginfoWikiPage(row.title);
                return [
                    wikiPage.link(),
                    row.location,
                    row.reason,
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
