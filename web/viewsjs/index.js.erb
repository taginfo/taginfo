class ChartKeysTagsRelations {
    id = 'key-tags-relations-lists';
    data;

    constructor(data) {
        this.data = data;
    }

    fill_list(list_name, data, func) {
        const element = document.getElementById(list_name);
        element.innerHTML = '';

        let i = 0;
        let texts = [];
        while (element.clientHeight < element.parentNode.clientHeight - 16 && i < data.length) {
            const text = func(data[i]);
            texts.push(text);
            element.innerHTML += text + '&nbsp;&bull; ';
            i++;
        }
        if (i < data.length - 2) {
            texts.pop();
            texts.pop();
        }
        element.innerHTML = texts.join('&nbsp;&bull; ') + '...';
    }

    draw() {
        this.fill_list('key_list', this.data.keys, d => (new TaginfoKey(d.text)).link());
        this.fill_list('tag_list', this.data.tags, d => (new TaginfoTag(d[0], d[1])).fullLink());
        this.fill_list('relation_list', this.data.relations, d => (new TaginfoRelation(d)).link());
    }

    resize() {
        this.draw();
    }
} // class ChartKeysTagsRelations

class ChartTagCloud {
    fontFamily = 'Impact';
    fontWeight = 'normal';
    id = 'tagcloud';
    element;
    data;

    constructor(data) {
        this.element = document.getElementById(this.id);
        this.data = data;
    }

    draw() {
        this.element.innerHTML = '';
        if (this.element.offsetParent === null) {
            return;
        }

        const width = this.element.getBoundingClientRect().width;
        const height = this.element.getBoundingClientRect().height;

        // The cloud function mangles the data in the words array, so we need to clone it
        const data = this.data.map(d => Object.assign({}, d));

        d3.layout.cloud().size([width, height])
            .words(data)
            .timeInterval(10)
            .rotate(() => ~~(Math.random() * 5) * 30 - 60)
            .font(this.fontFamily)
            .fontWeight(this.fontWeight)
            .fontSize(d => d.size)
            .on('end', (words) => this._draw.call(this, words, width, height))
            .start();
    }

    _draw(words, width, height) {
        // This color scheme isn't available in newer D3 versions, but we'll keep
        // it for the time being.
        const category20b = [ 3750777, 5395619, 7040719, 10264286, 6519097, 9216594, 11915115,
                            13556636, 9202993, 12426809, 15186514, 15190932, 8666169, 11356490,
                            14049643, 15177372, 8077683, 10834324, 13528509, 14589654 ].map(
                                value => new d3.rgb(value >> 16, value >> 8 & 255, value & 255));
        const fill = d3.scaleOrdinal(category20b);

        d3.select(this.element).append('svg')
            .append('g')
                .attr('transform', 'translate(' + width/2 + ',' + height/2 + ')')
                .selectAll('text')
                    .data(words)
                    .enter()
                    .append('svg:a')
                        .attr('xlink:href', d => (new TaginfoKey(d.text)).url())
                        .append('text')
                        .style('font-size', d => d.size + 'px')
                        .style('font-family', this.fontFamily)
                        .style('font-weight', this.fontWeight)
                        .style('fill', (d, i) => d3.rgb(fill(i)).darker(0.5))
                        .attr('text-anchor', 'middle')
                        .attr('transform', function(d) {
                            return 'translate(' + [d.x, d.y] + ')rotate(' + d.rotate + ')';
                        })
                        .text(d => d.text);
    }

    resize() {
        this.draw();
    }
} // class ChartTagCloud

function page_init() {
    up = function() {};

    const lists = new ChartKeysTagsRelations(context.data);
    widgetManager.addWidget(lists);
    lists.draw();

    const tagCloud = new ChartTagCloud(context.data.keys);
    widgetManager.addWidget(tagCloud);
    tagCloud.draw();
}
