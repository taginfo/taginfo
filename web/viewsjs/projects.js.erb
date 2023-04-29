const tabsConfig = {
    projects: function() {
        return new DynamicTable('grid-projects', {
            url: '/api/4/projects/all',
            colModel: [
                { display: h(texts.taginfo.project), name: 'name', width: 400, sortable: true },
                { display: h(texts.osm.keys), name: 'unique_keys', width: 40, sortable: true, align: 'right' },
                { display: h(texts.osm.tags), name: 'unique_tags', width: 40, sortable: true, align: 'right' },
                { display: h(texts.misc.description), name: 'description', width: 800 }
            ],
            searchitems: [
                { display: h(texts.taginfo.project) + '/' + h(texts.misc.description), name: 'name' }
            ],
            sortname: 'name',
            sortorder: 'asc',
            processRow: row => {
                const project = new TaginfoProject(row.id, row.name);
                return [
                    hover_expand(project.link()),
                    html_escape(row.unique_keys),
                    html_escape(row.unique_tags),
                    html_escape(row.description)
                ];
            }
        });
    },
    keys: function() {
        return new DynamicTable('grid-keys', {
            url: '/api/4/projects/keys',
            colModel: [
                { display: h(texts.osm.keys), name: 'key', width: 500, sortable: true },
                { display: h(texts.taginfo.projects), name: 'projects', width: 40, sortable: true, align: 'right' },
                { display: h(texts.taginfo.wiki), name: 'in_wiki', width: 20, sortable: true, align: 'center', title: h(texts.misc.in_wiki_tooltip) },
                { display: '<img src="/img/types/all.svg" width="16" height="16" alt=""/> ' + h(texts.osm.objects), name: 'count_all', width: 200, sortable: true, align: 'center', title: h(texts.misc.objects_tooltip) }
            ],
            searchitems: [
                { display: h(texts.osm.keys), name: 'key' }
            ],
            sortname: 'projects',
            sortorder: 'desc',
            processRow: row => {
                const key = new TaginfoKey(row.key);
                return [
                    hover_expand(key.link()),
                    key.link({tab: 'projects', content: html_escape(row.projects)}),
                    key.link({tab: 'wiki', content: fmt_checkmark(row.in_wiki)}),
                    fmt_value_with_percent(row.count_all, row.count_all_fraction),
                ];
            }
        });
    },
    tags: function() {
        return new DynamicTable('grid-tags', {
            url: '/api/4/projects/tags',
            colModel: [
                { display: h(texts.osm.tags), name: 'tag', width: 600, sortable: true },
                { display: h(texts.taginfo.projects), name: 'projects', width: 40, sortable: true, align: 'right' },
                { display: h(texts.taginfo.wiki), name: 'in_wiki', width: 20, sortable: true, align: 'center', title: h(texts.misc.in_wiki_tooltip) },
                { display: '<img src="/img/types/all.svg" width="16" height="16" alt=""/> ' + h(texts.osm.objects), name: 'count_all', width: 200, sortable: true, align: 'center', title: h(texts.misc.objects_tooltip) }
            ],
            searchitems: [
                { display: h(texts.osm.tags), name: 'tags' }
            ],
            sortname: 'projects',
            sortorder: 'desc',
            processRow: row => {
                const tag = new TaginfoTag(row.key, row.value);
                return [
                    hover_expand(tag.fullLink({ with_asterisk: true })),
                    tag.link({tab: 'projects', content: html_escape(row.projects)}),
                    tag.link({tab: 'wiki', content: fmt_checkmark(row.in_wiki)}),
                    fmt_value_with_percent(row.count_all, row.count_all_fraction),
                ];
            }
        });
    }
}

function page_init() {
    up = function() { window.location = build_link('/'); }
    initTabs(tabsConfig);
}
