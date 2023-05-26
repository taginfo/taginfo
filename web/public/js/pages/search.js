const tabsConfig = {
    keys: function(query) {
        return new DynamicTable('grid-keys', {
            url: '/api/4/keys/all',
            params: { query: query },
            colModel: [
                { display: h(texts.misc.count), name: 'count_all', width: 80, sortable: true, align: 'right' },
                { display: h(texts.osm.key), name: 'key', width: 500, sortable: true }
            ],
            sortname: 'count_all',
            sortorder: 'desc',
            processRow: row => {
                const key = new TaginfoKey(row.key);
                return [
                    fmt_with_ts(row.count_all),
                    key.link({ highlight: query })
                ];
            }
        });
    },
    values: function(query) {
        return new DynamicTable('grid-values', {
            url: '/api/4/search/by_value',
            params: { query: query },
            colModel: [
                { display: h(texts.misc.count), name: 'count_all', width: 80, sortable: true, align: 'right' },
                { display: h(texts.osm.key), name: 'key', width: 250, sortable: true },
                { display: h(texts.osm.value), name: 'value', width: 500, sortable: true }
            ],
            sortname: 'count_all',
            sortorder: 'desc',
            processRow: row => {
                const tag = new TaginfoTag(row.key, row.value);
                return [
                    fmt_with_ts(row.count_all),
                    tag.toKey().link(),
                    tag.link({ highlight: query })
                ];
            }
        });
    },
    relations: function(query) {
        return new DynamicTable('grid-relations', {
            url: '/api/4/relations/all',
            params: { query: query },
            colModel: [
                { display: h(texts.misc.count), name: 'count', width: 80, sortable: true, align: 'right' },
                { display: h(texts.osm.relation_type), name: 'rtype', width: 500, sortable: true }
            ],
            sortname: 'count',
            sortorder: 'desc',
            processRow: row => {
                const relation = new TaginfoRelation(row.rtype);
                return [
                    fmt_with_ts(row.count),
                    relation.link({ highlight: query })
                ];
            }
        });
    },
    roles: function(query) {
        return new DynamicTable('grid-roles', {
            url: '/api/4/search/by_role',
            params: { query: query },
            colModel: [
                { display: h(texts.misc.count), name: 'count_all', width: 80, sortable: true, align: 'right' },
                { display: h(texts.osm.relation_type), name: 'rtype', width: 250, sortable: true },
                { display: h(texts.osm.relation_member_roles), name: 'role', width: 500, sortable: true }
            ],
            sortname: 'count_all',
            sortorder: 'desc',
            processRow: row => {
                const relation = new TaginfoRelation(row.rtype);
                return [
                    fmt_with_ts(row.count_all),
                    relation.link(),
                    highlight(row.role, query)
                ];
            }
        });
    },
    fulltext: function(query) {
        return new DynamicTable('grid-fulltext', {
            url: '/api/4/search/by_keyword',
            params: { query: query },
            colModel: [
                { display: h(texts.osm.key), name: 'key', width: 300, sortable: true },
                { display: h(texts.osm.value), name: 'value', width: 500, sortable: true }
            ],
            sortname: 'key',
            sortorder: 'asc',
            processRow: row => {
                const key = new TaginfoKey(row.key);
                return [
                    key.link(),
                    row.value ? key.toTag(row.value).link() : ''
                ];
            }
        });
    }
};

function page_init() {
    initTabs(tabsConfig, [document.getElementById('query').textContent]);
}
