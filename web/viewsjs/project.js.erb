const tabsConfig = {
    tags: function(project) {
        return new DynamicTable('grid-tags', {
            url: '/api/4/project/tags',
            params: { project: project },
            colModel: [
                { display: h(texts.osm.tag), name: 'tag', width: 260, sortable: true },
                { display: h(texts.taginfo.wiki), name: 'in_wiki', width: 20, sortable: true, align: 'center', title: h(texts.misc.in_wiki_tooltip) },
                { display: h(texts.misc.count), name: 'count_all', width: 70, sortable: true, align: 'right', title: h(texts.pages.project.tags.count_all_tooltip) },
                { display: h(texts.osm.objects), name: 'objects', width:  80, title: h(texts.pages.project.tags.objects_tooltip) },
                { display: h(texts.pages.project.tags.description), name: 'description', width: 800 }
            ],
            searchitems: [
                { display: h(texts.osm.key) + '/' + h(texts.osm.value), name: 'key_value' }
            ],
            sortname: 'tag',
            sortorder: 'asc',
            processRow: row => {
                const project = new TaginfoProject(row.project_id, row.project_name, row.description, row.icon_url, row.doc_url);
                const keyOrTag = createKeyOrTag(row.key, row.value);
                return [
                    keyOrTag.fullLink({ with_asterisk: true }),
                    keyOrTag.toKey().link({ tab: 'wiki', content: fmt_checkmark(row.in_wiki) }),
                    fmt_with_ts(row.count_all),
                    fmt_type_icon('node',     row.on_node) +
                    fmt_type_icon('way',      row.on_way) +
                    fmt_type_icon('area',     row.on_area) +
                    fmt_type_icon('relation', row.on_relation),
                    fmt_project_tag_desc(row.description, row.icon_url, row.doc_url)
                ];
            }
        });
    }
};

function page_init() {
    up = function() { window.location = build_link('/projects'); }
    initTabs(tabsConfig, [context.project]);
}
