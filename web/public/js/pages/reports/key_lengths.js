class ChartKeyLengthHistogram {
    data;
    max;
    maxLength;

    constructor(data, maxLength) {
        this.data = data;
        this.max = Math.max(...data);
        this.maxLength = maxLength;
    }

    draw() {
        const barWidth = 6;
        const barSkip = 2;
        const barStep = barWidth + barSkip;
        const width = barStep * this.data.length;
        const height = Math.min(400, document.getElementById('tabs').getBoundingClientRect().height - 160);
        const margin = { top: 10, right: 15, bottom: 60, left: 60 };

        const scaleY = d3.scaleLinear()
                        .domain([0, this.max])
                        .range([height, 0]);

        const chart = d3.select('#canvas-histogram').append('svg')
                        .attr('width', width + margin.left + margin.right)
                        .attr('height', height + margin.top + margin.bottom)
                        .append('g')
                            .attr('transform', 'translate(' + margin.left + ', ' + margin.top + ')')
                            .call(function(c) {
                                c.append('rect')
                                    .attr('width', width)
                                    .attr('height', height + 10)
                                    .attr('y', -5)
                                    .style('fill', 'white')
                                    .style('stroke', '#d0d0c8')
                            });

        chart.append('g')
            .attr('class', 'x axis')
            .attr('transform', 'translate(0, ' + (height + 10) + ')')
            .append('text')
                .attr('x', width / 2)
                .attr('y', 36)
                .style('text-anchor', 'middle')
                .text(h(texts.reports.key_lengths.histogram.key_length));

        chart.append('g')
            .attr('class', 'y axis')
            .style('fill', 'black')
            .call(d3.axisLeft(scaleY))
            .append('text')
                .attr('transform', 'rotate(-90)')
                .attr('x', -height / 2)
                .attr('y', -50)
                .style('text-anchor', 'middle')
                .text(h(texts.reports.key_lengths.histogram.number_of_keys));

        chart.selectAll('rect')
            .data(this.data)
            .enter()
            .append('g')
                .call(c => {
                    c.append('g')
                        .attr('transform', function(d, i) { return 'translate(' + (i * barStep + barStep / 2) + ', ' + (height + 10) + ')';})
                        .style('display', function(d, i) { return i == 1 || i % 10 == 0 ? '' : 'none'; })
                        .call(t => {
                            t.append('text')
                                .attr('y', 16)
                                .style('text-anchor', 'middle')
                                .text((d, i) => i == this.maxLength ? '>=' + this.maxLength : i)
                        })
                        .append('line')
                            .style('stroke', 'black')
                            .style('shape-rendering', 'crispEdges')
                            .attr('y2', 6);
                })
            .append('rect')
                .style('fill', '#083e76')
                .attr('x', (d, i) => i * barStep)
                .attr('y', d => scaleY(d))
                .attr('width', barWidth)
                .attr('height', d => height - scaleY(d))
                .attr('title', (d, i) => '' + d + ' keys of length ' + i);

    }

} // class ChartKeyLengthHistogram

const tabsConfig = {
    keys: function() {
        return new DynamicTable('grid-keys', {
            url: '/api/4/keys/all',
            params: { include: 'prevalent_values' },
            colModel: [
                { display: h(texts.misc.length), name: 'length', width: 60, sortable: true, align: 'right' },
                { display: h(texts.osm.key), name: 'key', width: 180, sortable: true },
                { display: '<img src="/img/types/all.svg" width="16" height="16" alt=""/> ' + h(texts.osm.objects), name: 'count_all', width: 200, sortable: true, align: 'center', title: h(texts.misc.objects_tooltip) },
                { display: h(texts.taginfo.wiki), name: 'in_wiki', width: 20, sortable: true, align: 'center', title: h(texts.misc.in_wiki_tooltip) },
                { display: h(texts.osm.values), name: 'values_all', width: 70, sortable: true, align: 'right', title: h(texts.misc.values_tooltip) },
                { display: h(texts.misc.prevalent_values), name: 'prevalent_values', width: 550, title: h(texts.misc.prevalent_values_tooltip) }
            ],
            searchitems: [
                { display: h(texts.osm.key), name: 'key' }
            ],
            sortname: 'length',
            sortorder: 'asc',
            processRow: row => {
                const key = new TaginfoKey(row.key);
                return [
                    row.key.length,
                    key.link(),
                    fmt_value_with_percent(row.count_all, row.count_all_fraction),
                    key.link({tab: 'wiki', content: fmt_checkmark(row.in_wiki)}),
                    fmt_with_ts(row.values_all),
                    fmt_prevalent_value_list(key, row.prevalent_values)
                ];
            }
        });
    },
    histogram: function() {
        const chart = new ChartKeyLengthHistogram(context.data, context.maxLength);
        chart.draw();
    }
};

function page_init() {
    up = function() { window.location = build_link('/reports'); };
    initTabs(tabsConfig);
}
