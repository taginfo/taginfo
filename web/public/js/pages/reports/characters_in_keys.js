let tabsConfig = {
    statistics: () => new ChartCharactersInKeysStats(context.data, context.numKeys)
};

['plain', 'colon', 'letters', 'space', 'problem', 'rest'].forEach(function(category) {
    tabsConfig[category] = function() {
        return new DynamicTable('grid-' + category, {
            url: '/api/4/keys/all',
            params: { filter: 'characters_' + category, include: 'prevalent_values' },
            colModel: [
                { display: h(texts.osm.key), name: 'key', width: 250, sortable: true },
                { display: '<img src="/img/types/all.svg" width="16" height="16" alt=""/> ' + h(texts.osm.objects), name: 'count_all', width: 150, sortable: true, align: 'center', title: h(texts.misc.objects_tooltip) },
                { display: h(texts.osm.users), name: 'users_all', width: 44, sortable: true, align: 'right', title: h(texts.misc.users_tooltip) },
                { display: h(texts.taginfo.wiki), name: 'in_wiki', width: 20, sortable: true, align: 'center', title: h(texts.misc.in_wiki_tooltip) },
                { display: h(texts.osm.values), name: 'values_all', width: 70, sortable: true, align: 'right', title: h(texts.misc.values_tooltip) },
                { display: h(texts.misc.prevalent_values), name: 'prevalent_values', width: 600, title: h(texts.misc.prevalent_values_tooltip) }
            ],
            searchitems: [
                { display: h(texts.osm.key), name: 'key' }
            ],
            sortname: 'count_all',
            sortorder: 'desc',
            processRow: row => {
                const key = new TaginfoKey(row.key);
                return [
                    hover_expand(key.link()),
                    fmt_value_with_percent(row.count_all, row.count_all_fraction),
                    fmt_with_ts(row.users_all),
                    key.link({tab: 'wiki', content: fmt_checkmark(row.in_wiki)}),
                    fmt_with_ts(row.values_all),
                    fmt_prevalent_value_list(key, row.prevalent_values)
                ];
            }
        });
    };
});

class ChartCharactersInKeysStats {
    id = 'statistics';
    data;
    numKeys;

    constructor(data, numKeys) {
        this.data = data;
        this.numKeys = numKeys;
    }

    draw() {
        document.getElementById('canvas').innerHTML = '';
        const boxWidth = document.getElementById('statistics').getBoundingClientRect().width;
        const w = Math.min(968, boxWidth - 40);
        const h = 50;
        const colors = { 'A': '#2ca02c', 'B': '#98df8a', 'C': '#dbdb8d', 'D': '#d62728', 'E': '#ff9896', 'F': '#aec7e8' };

        let y = 0;
        this.data.forEach(function(d) {
            d['y'] = y;
            y += d['value'];
        });

        const scale = d3.scaleLinear()
                        .domain([0, this.numKeys])
                        .range([0, w]);

        const chart = d3.select('#canvas').append('svg')
                        .attr('width', w)
                        .attr('height', h);

        chart.selectAll('rect')
            .data(this.data)
            .enter()
            .append('g')
                .attr('transform', d => 'translate(' + scale(d['y']) + ', 0)')
                .call(function(c) {
                    c.append('rect')
                        .attr('height', 20)
                        .attr('width', d => scale(d['value']))
                        .style('fill', d => colors[d['label']]);
                })
                .append('text')
                    .attr('x', d => scale(d['value'] / 2))
                    .attr('y', 34)
                    .style('text-anchor', 'middle')
                    .text(d => d['label']);
    }

    resize() {
        this.draw();
    }
} // class ChartCharactersInKeysStats

function page_init() {
    up = function() { window.location = build_link('/reports'); };
    initTabs(tabsConfig);
}
