const tabsConfig = {
    overview: function(rtype) {
        return new DynamicTable('grid-overview', {
            url: '/api/4/relation/stats',
            params: { rtype: rtype },
            colModel: [
                { display: h(texts.pages.relation.overview.member_type), name: 'type', width: 100, sortable: true },
                { display: h(texts.pages.relation.overview.member_count), name: 'count', width: 260, sortable: true, align: 'right' }
            ],
            usePager: false,
            processRow: row => {
                return [
                    fmt_type_image(row.type),
                    fmt_with_ts(row.count)
                ];
            }
        });
    },
    roles: function(rtype) {
        return new DynamicTable('grid-roles', {
            url: '/api/4/relation/roles',
            params: { rtype: rtype },
            colModel: [
                { display: h(texts.osm.relation_member_role), name: 'role', width: 250, sortable: true },
                { display: '<img src="/img/types/all.svg" width="16" height="16" alt=""/> ' + h(texts.osm.relation_members), name: 'count_all_members', width: 250, sortable: true, align: 'center', title: h(texts.pages.relation.roles.objects_tooltip) },
                { display: '<img src="/img/types/node.svg" width="16" height="16" alt=""/> ' + h(texts.osm.relation_member_nodes), name: 'count_node_members', width: 250, sortable: true, align: 'center', title: h(texts.pages.relation.roles.nodes_tooltip) },
                { display: '<img src="/img/types/way.svg" width="16" height="16" alt=""/> ' + h(texts.osm.relation_member_ways), name: 'count_way_members', width: 250, sortable: true, align: 'center', title: h(texts.pages.relation.roles.ways_tooltip) },
                { display: '<img src="/img/types/relation.svg" width="16" height="16" alt=""/> ' + h(texts.osm.relation_member_relations), name: 'count_relation_members', width: 250, sortable: true, align: 'center', title: h(texts.pages.relation.roles.relations_tooltip) },
            ],
            searchitems: [
                { display: h(texts.osm.relation_member_role), name: 'role' }
            ],
            sortname: 'count_all_members',
            sortorder: 'desc',
            processRow: row => {
                return [
                    fmt_role(row.role),
                    fmt_value_with_percent(row.count_all_members, row.count_all_members_fraction),
                    fmt_value_with_percent(row.count_node_members, row.count_node_members_fraction),
                    fmt_value_with_percent(row.count_way_members, row.count_way_members_fraction),
                    fmt_value_with_percent(row.count_relation_members, row.count_relation_members_fraction)
                ];
            },
            empty: h(texts.pages.relation.roles.no_roles_info)
        });
    },
    graph: function(rtype) {
        return new ChartRoles('chart-roles', rtype);
    },
    wiki: function(rtype) {
        return new DynamicTable('grid-wiki', {
            url: '/api/4/relation/wiki_pages',
            params: { rtype: rtype },
            colModel: [
                { display: h(texts.misc.language), name: 'lang', width: 150 },
                { display: h(texts.pages.relation.wiki_pages.wiki_page), name: 'title', width: 160, align: 'right' },
                { display: h(texts.misc.description), name: 'description', width: 500 },
                { display: h(texts.misc.image), name: 'image', width: 300 }
            ],
            usePager: false,
            processRow: row => {
                const wikiPage = new TaginfoWikiPage(row.title);
                return [
                    fmt_language(row.lang, row.dir, row.language, row.language_en),
                    wikiPage.link(),
                    fmt_desc(row.lang, row.dir, row.description),
                    fmt_wiki_image_popup(row.image)
                ];
            }
        });
    },
    projects: function(rtype) {
        return new DynamicTable('grid-projects', {
            url: '/api/4/relation/projects',
            params: { rtype: rtype },
            colModel: [
                { display: h(texts.taginfo.project), name: 'project_name', width: 280, sortable: true },
                { display: h(texts.pages.relation.projects.description), name: 'description', width: 600 }
            ],
            searchitems: [
                { display: h(texts.taginfo.project) + '/' + h(texts.osm.value), name: 'project_value' }
            ],
            sortname: 'project_name',
            sortorder: 'asc',
            processRow: row => {
                const project = new TaginfoProject(row.project_id, row.project_name);
                return [
                    hover_expand(project.link()),
                    fmt_project_tag_desc(row.description, row.icon_url, row.doc_url)
                ];
            }
        });
    },
    characters: function(rtype) {
        return createCharactersTable(rtype);
    }
};

class ChartRoles {
    id;
    element;
    rtype;
    data;

    constructor(id, rtype) {
        this.id = id;
        this.element = document.getElementById(id);
        this.rtype = rtype;
    }

    load() {
        fetch(build_link('/api/4/relation/roles', { sortname: 'count_all_members', sortorder: 'asc', min_fraction: 0.01, rtype: this.rtype }))
            .then(response => response.json())
            .then(roles => this.init(roles));
    }

    init(roles) {
        if (roles.total == 0) {
            return;
        }

        this.data = [];
        for (let r of roles.data) {
            for (let type of ['node', 'way', 'relation']) {
                const count = r['count_' + type + '_members'];

                let title = '' + count + ' member ' + type + 's with ';
                let label;
                if (r.role === null) {
                    title += 'other roles';
                    label = '...';
                } else {
                    title += "role '" + r.role + "'";
                    label = r.role == '' ? '(empty)' : r.role;
                }

                this.data.push({
                    role: r.role,
                    type: type + 's',
                    value: count,
                    label: label,
                    title: title
                });
            }
        }

        this.draw();
    }

    resize() {
        this.draw();
    }

    draw() {
        if (this.data === undefined) {
            this.load();
            return;
        }

        this.element.innerHTML = '';

        const max_width = 800;
        let width = this.element.getBoundingClientRect().width - 20;
        if (width > max_width) {
            width = max_width;
        }
        const height = 360;
        const margin = 20;

        const x = d3.scaleLinear().range([0, width  - 2 * margin]);
        const y = d3.scaleLinear().range([0, height - 2 * margin]);

        const color = d3.scaleOrdinal(d3.schemeCategory10);

        const percent = d3.format('~%');

        const svg = d3.select(this.element).append('svg')
            .attr('width', width + 20)
            .attr('height', height)
            .append('g')
                .attr('transform', 'translate(' + 2 * margin + ',' + margin + ')');

        const root = d3.hierarchy(d3.group(this.data, d => d.type, d => d.role));

        const treemap = d3.treemap()
            .round(true)
            .tile(d3.treemapSliceDice)
            .size([width - 2 * margin, height - 2 * margin]);

        treemap(root.sum(d => d.value));

        svg.selectAll('.role')
            .data(root.leaves())
                .enter().append('a')
                    .attr('class', 'role')
                    .style('text-decoration', 'none')
                    .attr('xlink:title', d => d.data.title)
                    .call(function(c) {
                        c.append('rect')
                            .attr('x', d => d.x0)
                            .attr('y', d => d.y0)
                            .attr('width', d => d.x1 - d.x0)
                            .attr('height', d => d.y1 - d.y0)
                            .style('fill', d => color(d.data.role));
                        c.append('text')
                            .attr('x', d => d.x0 + (d.x1 - d.x0) / 2)
                            .attr('y', d => d.y0 + (d.y1 - d.y0) / 2)
                            .attr('dy', 4)
                            .attr('text-anchor', 'middle')
                            .style('fill', '#fff')
                            .text(function(d) {
                                if (d.x1 - d.x0 > 40 && d.y1 - d.y0 > 10) {
                                    return d.data.label;
                                } else {
                                    return '';
                                }
                            });
                    });

        // Add x-axis ticks.
        const xtick = svg.selectAll('.x')
            .data(x.ticks(width > 480 ? 10 : width > 240 ? 5 : 2))
            .enter().append('g')
                .attr('class', 'x')
                .attr('transform', d => 'translate(' + x(d) + ',' + y(1) + ')');

        xtick.append('line')
            .attr('y2', 6)
            .style('stroke', '#000');

        xtick.append('text')
            .attr('y', 8)
            .attr('text-anchor', 'middle')
            .attr('dy', '.71em')
            .text(percent);

        // Add y-axis ticks.
        const ytick = svg.selectAll('.y')
            .data(y.ticks(10))
            .enter().append('g')
                .attr('class', 'y')
                .attr('transform', d => 'translate(0,' + y(1 - d) + ')');

        ytick.append('line')
            .attr('x1', -6)
            .style('stroke', '#000');

        ytick.append('text')
            .attr('x', -8)
            .attr('text-anchor', 'end')
            .attr('dy', '.35em')
            .text(percent);

        // Add a group for each member type.
        const member_types_svg = svg.selectAll('.member_types')
            .data(root.children)
            .enter().append('g')
                .attr('class', 'member_types')
                .attr('transform', d => 'translate(' + d.x0 + ', -6)')
                .call(function(c) {
                    c.append('line')
                        .attr('x1', 0)
                        .attr('y1', -3.7)
                        .attr('x2', d => d.x1 - d.x0 )
                        .attr('y2', -3.7)
                        .style('stroke', '#000');
                    c.append('text')
                        .attr('x', 0)
                        .attr('text-anchor', 'start')
                        .text(d => (d.x1 - d.x0) > 10 ? '<' : '');
                    c.append('text')
                        .attr('x', d => d.x1 - d.x0 )
                        .attr('text-anchor', 'end')
                        .text(d => (d.x1 - d.x0) > 10 ? '>' : '');
                    c.append('text')
                        .attr('x', d => (d.x1 - d.x0) / 2 )
                        .attr('text-anchor', 'middle')
                        .style('stroke', '#ddddd4')
                        .style('stroke-width', 4)
                        .style('fill', '#000')
                        .text(d => (d.x1 - d.x0) > 40 ? texts.osm[d.data[0]] : '');
                    c.append('text')
                        .attr('x', d => (d.x1 - d.x0) / 2 )
                        .attr('text-anchor', 'middle')
                        .style('fill', '#000')
                        .text(d => (d.x1 - d.x0) > 40 ? texts.osm[d.data[0]] : '');
                });

    }
} // class ChartRoles

function page_init() {
    up = function() { window.location = build_link('/relations'); };
    activateJOSMButton();
    activateTagHistoryButton([{ type: 'relation', key: 'type', value: context.rtype }]);
    activateOhsomeButton('relations', 'type', context.rtype);

    const relation = new TaginfoRelation(context.rtype);
    document.querySelector('h1').innerHTML += relation.content();
    set_inner_html_to('taglink', relation.toTag().link());

    initTabs(tabsConfig, [context.rtype]);
}
