const tabsConfig = {
    overview: function(key, filter_type) {
        return [
            new DynamicTable('grid-overview', {
                url: '/api/4/key/stats',
                params: { key: key },
                colModel: [
                    { display: h(texts.misc.object_type), name: 'type', width: 100 },
                    { display: h(texts.pages.key.number_objects), name: 'count', width: 260, align: 'center' },
                    { display: h(texts.pages.key.number_values), name: 'value', width: 140, align: 'right' }
                ],
                usePager: false,
                processRow: row => {
                    return [
                        fmt_type_image(row.type),
                        fmt_value_with_percent(row.count, row.count_fraction),
                        fmt_with_ts(row.values)
                    ];
                }
            }),
            new ChartValues(key, filter_type, context.countAllValues)
        ];
    },
    values: function(key, filter_type, lang) {
        return new DynamicTable('grid-values', {
            url: '/api/4/key/values',
            params: { key: key, filter: filter_type, lang: lang },
            colModel: [
                { display: h(texts.osm.value), name: 'value', width: 200, sortable: true },
                { display: h(texts.misc.count), name: 'count', width: 260, sortable: true, align: 'center' },
                { display: h(texts.taginfo.wiki), name: 'in_wiki', width: 25, sortable: true, align: 'center', title: h(texts.misc.in_wiki_tooltip) },
                { display: h(texts.misc.description), name: 'description', width: 200, title: h(texts.pages.key.tag_description_from_wiki) }
            ],
            searchitems: [
                { display: h(texts.osm.value), name: 'value' }
            ],
            sortname: 'count',
            sortorder: 'desc',
            processRow: row => {
                return [
                    hover_expand(key.toTag(row.value).link()),
                    fmt_value_with_percent(row.count, row.fraction),
                    key.toTag(row.value).link({tab: 'wiki', content: fmt_checkmark(row.in_wiki)}),
                    fmt_desc(row.desclang, row.descdir, row.description)
                ];
            }
        });
    },
    combinations: function(key, filter_type) {
        return new DynamicTable('grid-combinations', {
            url: '/api/4/key/combinations',
            params: { key: key, filter: filter_type },
            colModel: [
                { display: h(texts.misc.count) + ' &rarr;', name: 'to_count', width: 260, sortable: true, align: 'center', title: h(texts.pages.key.other_keys_used.to_count_tooltip) },
                { display: h(texts.pages.key.other_keys_used.other), name: 'other_key', width: 400, sortable: true, title: h(texts.pages.key.other_keys_used.other_key_tooltip) },
                { display: '&rarr; ' + h(texts.misc.count), name: 'from_count', width: 260, sortable: true, align: 'center', title: h(texts.pages.key.other_keys_used.from_count_tooltip) }
            ],
            searchitems: [
                { display: h(texts.pages.key.other_keys_used.other), name: 'other_key' }
            ],
            sortname: 'to_count',
            sortorder: 'desc',
            processRow: row => {
                const otherKey = new TaginfoKey(row.other_key);
                return [
                    fmt_value_with_percent(row.together_count, row.to_fraction),
                    hover_expand(otherKey.link()),
                    fmt_value_with_percent(row.together_count, row.from_fraction),
                ];
            }
        });
    },
    similar: function(key) {
        return new DynamicTable('grid-similar', {
            url: '/api/4/key/similar',
            params: { key: key },
            colModel: [
                { display: h(texts.pages.key.similar.other), name: 'other_key', width: 300, sortable: true },
                { display: h(texts.misc.count), name: 'count_all', width: 60, sortable: true, align: 'right', title: h(texts.pages.key.similar.count_all_tooltip) },
                { display: h(texts.pages.key.similar.similarity), name: 'similarity', width: 60, sortable: true, align: 'right', title: h(texts.pages.key.similar.similarity_tooltip) }
            ],
            searchitems: [
                { display: h(texts.pages.key.similar.other), name: 'other_key' }
            ],
            sortname: 'other_key',
            sortorder: 'asc',
            processRow: row => {
                const otherKey = new TaginfoKey(row.other_key);
                return [
                    hover_expand(otherKey.link({ highlight: key })),
                    row.count_all,
                    row.similarity
                ];
            }
        });
    },
    chronology: function(key) {
        return new ChartChronology(build_link('/api/4/key/chronology', { key: key }), filter.value);
    },
    wiki: function(key, filter_type) {
        return new DynamicTable('grid-wiki', {
            url: '/api/4/key/wiki_pages',
            params: { key: key },
            colModel: [
                { display: h(texts.misc.language), name: 'lang', width: 150 },
                { display: h(texts.pages.key.wiki_pages.wiki_page), name: 'title', width: 160, align: 'right' },
                { display: h(texts.misc.description), name: 'description', width: 400 },
                { display: h(texts.misc.image), name: 'image', width: 120 },
                { display: h(texts.osm.objects), name: 'objects', width:  80 },
                { display: h(texts.misc.status), name: 'status', width: 60, title: h(texts.misc.approval_status) },
                { display: h(texts.pages.key.wiki_pages.implied_tags), name: 'tags_implied', width: 120 },
                { display: h(texts.pages.key.wiki_pages.combined_tags), name: 'tags_combination', width: 120 },
                { display: h(texts.pages.key.wiki_pages.linked_tags), name: 'tags_linked', width: 220 }
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
    projects: function(key, filter_type) {
        return new DynamicTable('grid-projects', {
            url: '/api/4/key/projects',
            params: { key: key, filter: filter_type },
            colModel: [
                { display: h(texts.taginfo.project), name: 'project_name', width: 280, sortable: true },
                { display: h(texts.osm.tag), name: 'tag', width: 220, sortable: true },
                { display: h(texts.osm.objects), name: 'objects', width:  80 },
                { display: h(texts.pages.key.projects.description), name: 'description', width: 200 }
            ],
            searchitems: [
                { display: h(texts.taginfo.project) + '/' + h(texts.osm.value), name: 'project_value' }
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
    characters: function(key, filter_type) {
        return createCharactersTable(key);
    }
};

class ChartValues {
    id = 'chart-values';
    key;
    url;
    data;
    countAllValues;

    constructor(key, filter, countAllValues) {
        this.key = key;
        this.url = build_link('/api/4/key/prevalent_values', { min_fraction: 0.02, key: key, filter: filter });
        this.countAllValues = countAllValues;
    }

    async load() {
        const response = await fetch(this.url);
        const json = await response.json();
        this.data = json.data;
        this.draw();
    }

    colors() {
        return ['#1f77b4', '#aec7e8', '#ff7f0e', '#ffbb78', '#2ca02c',
                '#98df8a', '#d62728', '#ff9896', '#9467bd', '#c5b0d5',
                '#8c564b', '#c49c94', '#e377c2', '#f7b6d2', '#7f7f7f',
                '#c7c7c7', '#bcbd22', '#dbdb8d', '#17becf', '#9edae5'];
    }

    draw() {
        set_inner_html_to('canvas-values', '');
        const width = 160;
        const height = Math.min(440, window.innerHeight - 300);

        let y = 0;
        this.data.forEach(function(d) {
            d['y'] = y;
            y += d['count'];
            if (d.value === null) {
                d.label = '(other)';
            } else {
                d.label = d.value;
            }
        });

        const scale = d3.scaleLinear()
                        .domain([0, this.countAllValues])
                        .range([0, height]);

        const color = d3.scaleOrdinal()
                        .range(this.colors());

        const chart = d3.select('#canvas-values').append('svg')
                        .attr('width', width)
                        .attr('height', height);

        chart.selectAll('rect')
            .data(this.data)
            .enter()
            .append('svg:a')
                .attr('href', d => this.key.toTag(d.label).url())
                .attr('transform', d => 'translate(10, ' + scale(d['y']) + ')')
                .call(function(c) {
                    c.append('rect')
                        .attr('width', 20)
                        .attr('height', d => scale(d['count']))
                        .style('fill', (d, i) => color(i));
                })
                .append('text')
                    .attr('x', 25)
                    .attr('y', d => scale(d['count'] / 2))
                    .attr('dy', '0.5em')
                    .text(d => d.label);

        const other = document.querySelector('svg a[href$="(other)"]');
        if (other) {
            other.removeAttribute('href');
            other.style.textDecoration = 'none';
        }
    }

    resize() {
        this.draw();
    }
} // class ChartValues

function page_init() {
    const key = new TaginfoKey(context.key);

    up = function() { window.location = build_link('/keys'); }

    activateJOSMButton();

    const filter = document.getElementById('filter');
    filter.addEventListener('change', function(element) {
        if (element.target.value != 'all') {
            key.params.filter = element.target.value;
        }
        window.location = key.url();
    });

    activateTagHistoryButton([{ type: filter.value, key: context.key }]);
    activateOhsomeButton(filter.value, context.key);

    document.querySelector('h1').innerHTML = key.content();

    new ComparisonListDisplay(key);

    initTabs(tabsConfig, [key, filter.value, context.lang]);
}
