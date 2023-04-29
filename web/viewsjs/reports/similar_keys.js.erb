function page_init() {
    up = function() { window.location = build_link('/reports'); };
    widgetManager.addWidget(createDynamicTable('grid-keys', {
        url: '/api/4/keys/similar',
        colModel: [
            { display: h(texts.reports.similar_keys.key_common), name: 'key_common', width: 350, sortable: true },
            { display: h(texts.reports.similar_keys.count_common), name: 'count_all_common', width: 100, sortable: true, align: 'right' },
            { display: h(texts.reports.similar_keys.key_rare), name: 'key_rare', width: 350, sortable: true },
            { display: h(texts.reports.similar_keys.count_rare), name: 'count_all_rare', width: 100, sortable: true, align: 'right' },
            { display: h(texts.reports.similar_keys.similarity), name: 'similarity', width: 100, sortable: true, align: 'right' }
        ],
        searchitems: [
            { display: h(texts.osm.key), name: 'common_key' }
        ],
        sortname: 'count_all_common',
        sortorder: 'desc',
        processRow: row => {
            const commonKey = new TaginfoKey(row.key_common);
            const rareKey = new TaginfoKey(row.key_rare);
            return [
                    hover_expand(commonKey.link()),
                    row.count_all_common,
                    hover_expand(rareKey.link()),
                    row.count_all_rare,
                    row.similarity
            ];
        }
    }));
}

