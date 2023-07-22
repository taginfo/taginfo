const tabsConfig = {
    overview: function(key, value, filter_type) {
        return new DynamicTable('grid-overview', {
            url: '/api/4/tag/stats',
            params: { key: key, value: value },
            colModel: [
                { display: h(texts.misc.object_type), name: 'type', width: 100 },
                { display: h(texts.pages.tag.number_objects), name: 'count', width: 260, align: 'center' }
            ],
            usePager: false,
            processRow: row => {
                return [
                    fmt_type_image(row.type),
                    fmt_value_with_percent(row.count, row.count_fraction)
                ];
            }
        });
    },
    combinations: function(key, value, filter_type) {
        return new DynamicTable('grid-combinations', {
            url: '/api/4/tag/combinations',
            params: { key: key, value: value, filter: filter_type },
            colModel: [
                { display: h(texts.misc.count) + ' &rarr;', name: 'to_count', width: 260, sortable: true, align: 'center', title: h(texts.pages.tag.other_tags_used.to_count_tooltip) },
                { display: h(texts.pages.tag.other_tags_used.other), name: 'other_tag', width: 400, sortable: true, title: h(texts.pages.tag.other_tags_used.other_key_tooltip) },
                { display: '&rarr; ' + h(texts.misc.count), name: 'from_count', width: 260, sortable: true, align: 'center', title: h(texts.pages.tag.other_tags_used.from_count_tooltip) }
            ],
            searchitems: [
                { display: h(texts.pages.tag.other_tags_used.other), name: 'other_tag' }
            ],
            sortname: 'to_count',
            sortorder: 'desc',
            processRow: row => {
                const other = createKeyOrTag(row.other_key, row.other_value);
                return [
                    fmt_value_with_percent(row.together_count, row.to_fraction),
                    hover_expand(other.fullLink({ with_asterisk: true })),
                    fmt_value_with_percent(row.together_count, row.from_fraction),
                ];
            }
        });
    },
    chronology: function(key, value) {
        return new ChartChronology(build_link('/api/4/tag/chronology', { key: key, value: value }), filter.value);
    },
    wiki: function(key, value) {
        if (!document.getElementById('grid-wiki')) {
            return [];
        }
        return new DynamicTable('grid-wiki', {
            url: '/api/4/tag/wiki_pages',
            params: { key: key, value: value },
            colModel: [
                { display: h(texts.misc.language), name: 'lang', width: 150 },
                { display: h(texts.pages.tag.wiki_pages.wiki_page), name: 'title', width: 200, align: 'right' },
                { display: h(texts.misc.description), name: 'description', width: 400 },
                { display: h(texts.misc.image), name: 'image', width: 120 },
                { display: h(texts.osm.objects), name: 'objects', width:  80 },
                { display: h(texts.misc.status), name: 'status', width: 60, title: h(texts.misc.approval_status) },
                { display: h(texts.pages.tag.wiki_pages.implied_tags), name: 'tags_implied', width: 120 },
                { display: h(texts.pages.tag.wiki_pages.combined_tags), name: 'tags_combination', width: 120 },
                { display: h(texts.pages.tag.wiki_pages.linked_tags), name: 'tags_linked', width: 220 }
            ],
            usePager: false,
            processRow: row => {
                const wikiPage = new TaginfoWikiPage(row.title);
                return [
                    fmt_language(row.lang, row.dir, row.language, row.language_en),
                    wikiPage.link(),
                    fmt_desc(row.lang, row.dir, row.description),
                    fmt_wiki_image_popup(row.image),
                    fmt_type_icon('node',     row.on_node) +
                    fmt_type_icon('way',      row.on_way) +
                    fmt_type_icon('area',     row.on_area) +
                    fmt_type_icon('relation', row.on_relation),
                    fmt_status(row.status),
                    fmt_key_or_tag_list(row.tags_implies),
                    fmt_key_or_tag_list(row.tags_combination),
                    fmt_key_or_tag_list(row.tags_linked)
                ];
            }
        });
    },
    projects: function(key, value, filter_type) {
        return new DynamicTable('grid-projects', {
            url: '/api/4/tag/projects',
            params: { key: key, value: value, filter: filter_type },
            colModel: [
                { display: h(texts.taginfo.project), name: 'project_name', width: 280, sortable: true },
                { display: h(texts.osm.tag), name: 'tag', width: 220, sortable: true },
                { display: h(texts.osm.objects), name: 'objects', width:  80 },
                { display: h(texts.pages.tag.projects.description), name: 'description', width: 200 }
            ],
            searchitems: [
                { display: h(texts.taginfo.project), name: 'project_name' }
            ],
            sortname: 'tag',
            sortorder: 'asc',
            processRow: row => {
                const project = new TaginfoProject(row.project_id, row.project_name);
                const rowKeyOrTag = createKeyOrTag(row.key, row.value);
                return [
                    hover_expand(project.link()),
                    hover_expand(rowKeyOrTag.fullLink({ with_asterisk: true })),
                    fmt_type_icon('node',     row.on_node) +
                    fmt_type_icon('way',      row.on_way) +
                    fmt_type_icon('area',     row.on_area) +
                    fmt_type_icon('relation', row.on_relation),
                    fmt_project_tag_desc(row.description, row.icon_url, row.doc_url)
                ];
            }
        });
    },
    characters: function(key, value, filter_type) {
        return createCharactersTable(value);
    }
};

function page_init() {
    const key = new TaginfoKey(context.key);
    const tag = key.toTag(context.value);

    activateJOSMButton();

    const filter = document.getElementById('filter');
    filter.addEventListener('change', function(element) {
        if (element.target.value != 'all') {
            tag.params.filter = element.target.value;
        }
        window.location = tag.url();
    });

    activateTagHistoryButton([{ type: filter.value, key: context.key, value: context.value }]);
    activateOhsomeButton(filter.value, context.key, context.value);

    up = function() { window.location = key.url(); };
    document.querySelector('h1').innerHTML = key.link() + '=' + tag.content();

    new ComparisonListDisplay(tag);

    set_inner_html_to('keylink', key.link());
    set_inner_html_to('relationlink', (new TaginfoRelation(context.value)).link());

    initTabs(tabsConfig, [context.key, context.value, filter.value]);
}
