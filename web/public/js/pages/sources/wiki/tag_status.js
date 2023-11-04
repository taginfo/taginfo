var keysTable, tagsTable;

const tabsConfig = {
    keys: function(status) {
        keysTable = new DynamicTable('grid-keys', {
            url: '/api/4/wiki/key_status',
            params: { status: status },
            colModel: [
                { display: h(texts.misc.status), name: 'status', width: 80 },
                { display: h(texts.osm.key), name: 'key', width: 200 },
                { display: h(texts.misc.language), name: 'lang', width: 80 },
            ],
            usePager: true,
            processRow: row => {
                const key = new TaginfoKey(row.key);
                key.tab = 'wiki';
                return [
                    fmt_status(row.status),
                    hover_expand(key.fullLink()),
                    row.langs.join(', ')
                ];
            }
        });
        return [
            keysTable
        ];
    },
    tags: function(status) {
        tagsTable = new DynamicTable('grid-tags', {
            url: '/api/4/wiki/tag_status',
            params: { status: status },
            colModel: [
                { display: h(texts.misc.status), name: 'status', width: 80 },
                { display: h(texts.osm.tag), name: 'tag', width: 200 },
                { display: h(texts.misc.language), name: 'lang', width: 80 },
            ],
            usePager: true,
            processRow: row => {
                const tag = new TaginfoTag(row.key, row.value);
                tag.tab = 'wiki';
                return [
                    fmt_status(row.status),
                    hover_expand(tag.fullLink()),
                    row.langs.join(', ')
                ];
            }
        });
        return [
            tagsTable
        ];
    },
    inconsistent_keys: function() {
        return new DynamicTable('grid-inconsistent-keys', {
            url: '/api/4/wiki/inconsistent_key_status',
            colModel: [
                { display: h(texts.osm.key), name: 'key', width: 200 },
                { display: h(texts.misc.status), name: 'status', width: 200 },
            ],
            usePager: true,
            processRow: row => {
                const key = new TaginfoKey(row.key);
                key.tab = 'wiki';
                return [
                    hover_expand(key.fullLink()),
                    Object.entries(row.counts).map((e) => e[1] + ' x ' + fmt_status(e[0])).join(', ')
                ];
            }
        });
    },
    inconsistent_tags: function() {
        return new DynamicTable('grid-inconsistent-tags', {
            url: '/api/4/wiki/inconsistent_tag_status',
            colModel: [
                { display: h(texts.osm.tag), name: 'tag', width: 200 },
                { display: h(texts.misc.status), name: 'status', width: 200 },
            ],
            usePager: true,
            processRow: row => {
                const tag = new TaginfoTag(row.key, row.value);
                tag.tab = 'wiki';
                return [
                    hover_expand(tag.fullLink()),
                    Object.entries(row.counts).map((e) => e[1] + ' x ' + fmt_status(e[0])).join(', ')
                ];
            }
        });
    },
};

function page_init() {
    up = function() { window.location = build_link('/sources/wiki'); }
    const filter_key = document.getElementById('status-filter-key');
    const filter_tag = document.getElementById('status-filter-tag');
    initTabs(tabsConfig, [filter_key.value]);
    filter_key.addEventListener('change', function(element) {
        window.location.search = new URLSearchParams({ 'status': element.target.value });
    });
    filter_tag.addEventListener('change', function(element) {
        window.location.search = new URLSearchParams({ 'status': element.target.value });
    });
}
