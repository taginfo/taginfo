const tabsConfig = {
    tags: function(query) {
        const q = query.split('=', 2);
        return new DynamicTable('grid-tags', {
            url: '/api/4/search/by_key_and_value',
            params: { query: query },
            colModel: [
                { display: h(texts.misc.count), name: 'count_all', width: 80, sortable: true, align: 'right' },
                { display: h(texts.osm.key), name: 'key', width: 300, sortable: true },
                { display: h(texts.osm.value), name: 'value', width: 500, sortable: true }
            ],
            sortname: 'count_all',
            sortorder: 'desc',
            processRow: row => {
                const key = new TaginfoKey(row.key);
                return [
                    fmt_with_ts(row.count_all),
                    key.link({ highlight: q[0] }),
                    key.toTag(row.value).link({ highlight: q[1] })
                ];
            }
        });
    },
};

function page_init() {
    initTabs(tabsConfig, [document.getElementById('query').textContent]);
}
