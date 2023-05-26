class ChartHistory {
    key;
    data;
    element;

    constructor(key, data) {
        this.key = key;
        this.data = data;
        this.element = document.getElementById('canvas_' + key);

        for (let d of this.data) {
            d[0] = new Date(d[0]);
        };
    }

    draw() {
        this.element.innerHTML = '';
        const box = document.getElementById(this.key).getBoundingClientRect();

        const radius = 1.5;
        const w = Math.min(900, box.width - 140);
        const h = Math.min(400, box.height - 130);
        const margin = { top: 10, right: 15, bottom: 40, left: 80 };

        const t0 = this.data[0][0];
        const t1 = this.data[this.data.length - 1][0];

        const max = d3.max(this.data, d => d[1]);

        const scaleX = d3.scaleTime()
                         .domain([t0, t1])
                         .range([0, w]);

        const axisX = d3.axisBottom(scaleX)
                        .tickFormat(d3.timeFormat(box.width > 800 ? '%b %Y' : '%Y'));

        const scaleY = d3.scaleLinear()
                         .domain([0, max])
                         .range([h, 0]);

        const chart = d3.select(this.element).append('svg')
                        .attr('width', w + margin.left + margin.right)
                        .attr('height', h + margin.top + margin.bottom)
                        .append('g')
                            .attr('transform', 'translate(' + margin.left + ', ' + margin.top + ')')
                            .call(function(c) {
                                c.append('rect')
                                    .attr('width', w + 10)
                                    .attr('height', h + 10)
                                    .attr('x', -5)
                                    .attr('y', -5)
                                    .style('fill', 'white')
                                    .style('stroke', '#d0d0c8')
                            });

        chart.append('g')
            .attr('class', 'x axis')
            .attr('transform', 'translate(0, ' + (h + 5) + ')')
            .call(axisX);

        chart.append('g')
            .attr('class', 'y axis')
            .attr('transform', 'translate(-5, 0)')
            .call(d3.axisLeft(scaleY));

        chart.selectAll('circle')
            .data(this.data)
            .enter()
            .append('circle')
                .style('fill', '#083e76')
                .attr('cx', (d, i) => scaleX(d[0]))
                .attr('cy', d => scaleY(d[1]))
                .attr('r', radius)
                .attr('title', (d, i) => d3.timeFormat('%Y-%m-%d')(d[0]) + ': ' + d[1]);

    }

    resize() {
        this.draw();
    }
} // class ChartHistory

const tabsConfig = {
    num_keys: data => new ChartHistory('num_keys', data['num_keys']),
    num_tags: data => new ChartHistory('num_tags', data['num_tags']),
    relation_types: data => new ChartHistory('relation_types', data['relation_types'])
}

function page_init() {
    up = function() { window.location = build_link('/reports'); };
    initTabs(tabsConfig, [context.data]);
}
