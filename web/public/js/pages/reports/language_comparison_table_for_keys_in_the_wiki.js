function page_init() {
    up = function() { window.location = build_link('/reports'); };

    let columns = [
        { display: h(texts.osm.key), name: 'key', width: 160, sortable: true }
    ]

    for (const lang of context.languages) {
        columns.push({
            display: '<span class="badge lang" style="padding: 0">' + h(lang[0]) + '</span>',
            name: h(lang[0]),
            align: 'center',
            width: lang[0].length * 8.5,
            title: h(lang[1])
        })
    }

    widgetManager.addWidget(createDynamicTable('grid-keys', {
        url: '/api/4/keys/wiki_pages',
        colModel: columns,
        searchitems: [
            { display: h(texts.osm.key), name: 'key' }
        ],
        sortname: 'key',
        sortorder: 'asc',
        processRow: row => {
            let d = new Array(1 + context.languages.length);
            const key = new TaginfoKey(row.key);
            d[0] = hover_expand(key.link());
            d = d.fill('', 1, context.languages.length + 1);
            for (const lang in row.lang) {
                ptype = row.lang[lang];
                d[context.lang_to_idx[lang]] = '<img width="16" height="16" src="/img/sources/wiki/wiki-' + ptype + '.png" alt="[' + ptype + ']"/>';
            }
            return d;
        }
    }));
}
