function page_init() {
    up = function() { window.location = build_link('/reports'); };
    widgetManager.addWidget(createDynamicTable('grid-problems', {
        url: '/api/0/wiki/problems',
        colModel: [
            { display: h(texts.reports.wiki_problems.wiki_page), name: 'title', width: 280, sortable: true },
            { display: h(texts.reports.wiki_problems.location), name: 'location', width: 140, sortable: true },
            { display: h(texts.reports.wiki_problems.reason), name: 'reason', width: 280, sortable: true },
            { display: h(texts.reports.wiki_problems.lang), name: 'lang', width: 50, sortable: true },
            { display: h(texts.osm.tag), name: 'tag', width: 160, sortable: true },
            { display: h(texts.reports.wiki_problems.info), name: 'info', width: 600 }
        ],
        sortname: 'title',
        sortorder: 'asc',
        processRow: row => {
            const wikiPage = new TaginfoWikiPage(row.title);
            const keyOrTag = createKeyOrTag(row.key, row.value);
            return [
                wikiPage.link(),
                row.location,
                row.reason,
                tag('span', html_escape(row.lang), { 'class': 'lang' }),
                row.key === null ? '' : keyOrTag.fullLink({ with_asterisk: true }),
                row.info ? html_escape(row.info) : ''
            ];
        }
    }));
}
