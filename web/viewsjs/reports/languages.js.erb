function page_init() {
    up = function() { window.location = build_link('/reports'); };
    widgetManager.addWidget(createDynamicTable('grid-langs', {
        url: '/api/4/wiki/languages',
        colModel: [
            { display: h(texts.reports.languages.code), name: 'code', width: 60, sortable: true },
            { display: h(texts.reports.languages.native_name), name: 'native_name', width: 150, sortable: true },
            { display: h(texts.reports.languages.english_name), name: 'english_name', width: 150, sortable: true },
            { display: h(texts.reports.languages.wiki_key_pages), name: 'wiki_key_pages', width: 260, sortable: true, align: 'center' },
            { display: h(texts.reports.languages.wiki_tag_pages), name: 'wiki_tag_pages', width: 260, sortable: true, align: 'center' }
        ],
        sortname: 'code',
        sortorder: 'asc',
        usePager: false,
        processRow: row => {
            return [
                span(row.code, 'badge lang'),
                fmt_desc(row.code, row.dir, row.native_name),
                row.english_name,
                fmt_value_with_percent(row.wiki_key_pages, row.wiki_key_pages_fraction),
                fmt_value_with_percent(row.wiki_tag_pages, row.wiki_tag_pages_fraction)
            ];
        }
    }));
}
