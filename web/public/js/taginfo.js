// taginfo.js

var grids = {};
var current_grid = '';

function resize_home() {
    var tagcloud = jQuery('#tagcloud');
    tagcloud.empty();
    tagcloud.height(0);

    resize_box();

    var height = tagcloud.parent().innerHeight();
    tagcloud.parent().children().each(function(index) {
        if (this.id != 'tagcloud') {
            height -= jQuery(this).outerHeight(true);
        }
    });
    tagcloud.height(height - 20);

    var tags = tagcloud_data();
    var cloud = '';
    for (var i=0; i < tags.length; i++) {
        cloud += '<a href="/keys/' + tags[i][0] + '" style="font-size: ' + tags[i][1] + 'px;">' + tags[i][0] + '</a> ';
    }
    tagcloud.append(cloud);

    var tags = tagcloud.children().toArray().sort(function(a, b) {
        return parseInt(jQuery(a).css('font-size')) - parseInt(jQuery(b).css('font-size'));
    });

    while (tagcloud.get(0).scrollHeight > tagcloud.height()) {
        jQuery(tags.shift()).remove();
    }
}

function resize_box() {
    var height = jQuery(window).height();

    height -= jQuery('div#header').outerHeight(true);
    height -= jQuery('div.pre').outerHeight(true);
    height -= jQuery('.ui-tabs-nav').outerHeight(true);
    height -= jQuery('div#footer').outerHeight(true);

    var wrapper = jQuery('.resize,.ui-tabs-panel');
    wrapper.outerHeight(height);
}

function resize_grid() {
    if (grids[current_grid]) {
        var grid = grids[current_grid][0].grid;
        var oldrp = grid.getRp();
        var rp = calculate_flexigrid_rp(jQuery(grids[current_grid][0]).parents('.resize,.ui-tabs-panel'));
        if (rp != oldrp) {
            grid.newRp(rp);
            grid.fixHeight();
        }
    }
}

function hover_expand(text) {
    return '<span class="overflow">' + text + '</span>';
}

function empty(text) {
    return '<span class="empty">' + text + '</span>';
}

function print_wiki_link(title, options) {
    if (title == '') {
        return '';
    }

    if (options && options.edit) {
        path = 'w/index.php?action=edit&title=' + title;
    } else {
        path = 'wiki/' + title;
    }

    return '<a class="extlink" rel="nofollow" href="http://wiki.openstreetmap.org/' + path + '" target="_blank">' + title + '</a>';
}

function print_language(code, native_name, english_name) {
    return '<span class="lang" title="' + native_name + ' (' + english_name + ')">' + code + '</span> ' + native_name;
}

function print_key_list(list) {
    return jQuery.map(list, function(key, i) {
        return link_to_key(key);
    }).join(' &bull; ');
}

function print_key_or_tag_list(list) {
    return jQuery.map(list, function(tag, i) {
        if (tag.match(/=/)) {
            var el = tag.split('=', 2);
            return link_to_tag(el[0], el[1]);
        } else {
            return link_to_key(tag);
        }
    }).join(' &bull; ');
}

function print_prevalent_value_list(key, list) {
    if (list.length == 0) {
        return empty(texts.misc.values_less_than_one_percent);
    }
    return jQuery.map(list, function(item, i) {
        return link_to_value_with_title(key, item.value, '(' + (item.fraction * 100).toFixed(2) + '%)');
    }).join(' &bull; ');
}

function link_to_value_with_title(key, value, extra) {
    var k = encodeURIComponent(key),
        v = encodeURIComponent(value),
        title = html_escape(value) + ' ' + extra;

    if (key.match(/[=\/]/) || value.match(/[=\/]/)) {
        return '<a class="taglink" href="/tags/?key=' + k + '&value=' + v + '" title="' + title + '">' + pp_value(value) + '</a>';
    } else {
        return '<a class="taglink" href="/tags/' + k + '=' + v + '" title="' + title + '">' + pp_value(value) + '</a>';
    }
}

function print_tag_list(key, list) {
    return jQuery.map(list, function(value, i) {
        return link_to_value(key, value);
    }).join(' &bull; ');
}

function print_value_with_percent(value, fraction) {
    var v1 = print_with_ts(value),
        v2 = fraction.print_as_percent();
    return '<div class="value">' + v1 + '</div><div class="fraction">' + v2 + '</div><div class="bar" style="width: ' + (fraction*100).toFixed() + 'px;"></div>';
}

// capitalize a string
String.prototype.capitalize = function() {
    return this.substr(0, 1).toUpperCase() + this.substr(1);
}

function print_image(type) {
    type = type.replace(/s$/, '');
    var name;
    if (type == 'all') {
        name = texts.misc.all;
    } else {
        name = texts.osm[type];
    }
    return '<img src="/img/types/' + type + '.16.png" alt="[' + name + ']" title="' + name + '" width="16" height="16"/>';
}

// print a number with thousand separator
function print_with_ts(value) {
    if (value === null) {
        return '-';
    } else {
        return value.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1&thinsp;');
    }
}

// print a number as percent value with two digits after the decimal point
Number.prototype.print_as_percent = function() {
    return (this * 100).toFixed(2) + '%';
};

var pp_chars = '!"#$%&()*+,-/;<=>?@[\\]^`{|}~' + "'";

function pp_key(key) {
    if (key == '') {
        return '<span class="badchar empty">' + texts.misc.empty_string + '</span>';
    }

    var result = '',
        length = key.length;

    for (var i=0; i<length; i++) {
        var c = key.charAt(i);
        if (pp_chars.indexOf(c) != -1) {
            result += '<span class="badchar">' + c + '</span>';
        } else if (c == ' ') {
            result += '<span class="badchar">&#x2423;</span>';
        } else if (c.match(/\s/)) {
            result += '<span class="whitespace">&nbsp;</span>';
        } else {
            result += c;
        }
    }

    return result;
}

function pp_value(value) {
    if (value == '') {
        return '<span class="badchar empty">' + texts.misc.empty_string + '</span>';
    }
    return value.replace(/ /g, '&#x2423;').replace(/\s/g, '<span class="whitespace">&nbsp;</span>');
}

function pp_value_replace(value) {
    return value.replace(/ /g, '&#x2423;').replace(/\s/g, '<span class="whitespace">&nbsp;</span>');
}

function pp_value_with_highlight(value, highlight) {
    //var values = value.split(new RegExp(highlight, 'i'));
    var values = value.split(highlight);
    values = jQuery.map(values, function(value, i) {
        return pp_value_replace(value);
    });
    highlight = pp_value_replace(highlight);
    return values.join('<b>' + highlight + '</b>');
}

function link_to_key_with_highlight(key, highlight) {
    var k = encodeURIComponent(key);

    if (key.match(/[=\/]/)) {
        return '<a class="taglink" href="/keys/?key=' + k + '">' + pp_key_with_highlight(key, highlight) + '</a>';
    } else {
        return '<a class="taglink" href="/keys/'      + k + '">' + pp_key_with_highlight(key, highlight) + '</a>';
    }
}

function link_to_value_with_highlight(key, value, highlight) {
    return '<a class="taglink" href="' + url_to_value(key, value) + '">' + pp_value_with_highlight(value, highlight) + '</a>';
}

function html_escape(text) {
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function link_to_key(key) {
    var k = encodeURIComponent(key);

    if (key.match(/[=\/]/)) {
        return '<a class="taglink" href="/keys/?key=' + k + '">' + pp_key(key) + '</a>';
    } else {
        return '<a class="taglink" href="/keys/'      + k + '">' + pp_key(key) + '</a>';
    }
}

function link_to_key_with_highlight(key, highlight) {
    var k = encodeURIComponent(key);

    var re = new RegExp('(' + highlight + ')', 'g');
    var hk = key.replace(re, "<b>$1</b>");

    if (key.match(/[=\/]/)) {
        return '<a class="taglink" href="/keys/?key=' + k + '">' + hk + '</a>';
    } else {
        return '<a class="taglink" href="/keys/'      + k + '">' + hk + '</a>';
    }
}

function link_to_value(key, value) {
    return '<a class="taglink" href="' + url_to_value(key, value) + '">' + pp_value(value) + '</a>';
}

function url_to_value(key, value) {
    var k = encodeURIComponent(key),
        v = encodeURIComponent(value);
    if (key.match(/[=\/]/) || value.match(/[=\/]/)) {
        return '/tags/?key=' + k + '&value=' + v;
    } else {
        return '/tags/' + k + '=' + v;
    }
}

function link_to_tag(key, value) {
    return link_to_key(key) + '=' + link_to_value(key, value);
}

function link_to_key_or_tag(key, value) {
    var link = link_to_key(key);
    if (value && value != '') {
        link += '=' + link_to_value(key, value);
    } else {
        link += '=*';
    }
    return link;
}

jQuery(document).ready(function() {
    jQuery('select').customStyle();

    jQuery.getQueryString = (function(a) {
        if (a == "") return {};
        var b = {};
        for (var i = 0; i < a.length; i++) {
            var p=a[i].split('=');
            b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
        }
        return b;
    })(window.location.search.substr(1).split('&'))

    jQuery('*[title]').tipsy({ opacity: 1, delayIn: 500 });

    resize_box();

    if (typeof page_init === 'function') {
        page_init();
    }

    jQuery('#locale').bind('change', function() {
        jQuery('#set_language').submit();
    });

    jQuery('#search').autocomplete({
        minLength: 2,
        source: '/search/suggest?format=simple',
        delay: 10,
        select: function(event, ui) {
            var query = ui.item.value;
            if (query.match(/=/)) {
                window.location = '/tags/' + ui.item.value;
            } else {
                window.location = '/keys/' + ui.item.value;
            }
        }
    }).focus();

    jQuery(window).resize(function() {
        resize_box();
        resize_grid();
    });
});

/* ============================ */

var flexigrid_defaults = {
    method        : 'GET',
    dataType      : 'json',
    showToggleBtn : false,
    height        : 'auto',
    usepager      : true,
    useRp         : false,
    onSuccess     : function(grid) {
        grid.fixHeight();
    }
};

function calculate_flexigrid_rp(box) {
    var height = box.innerHeight();

    height -= box.children('h2').outerHeight(true);
    height -= box.children('.boxpre').outerHeight(true);
    height -= box.children('.pDiv').outerHeight();
    height -= box.children('.pHiv').outerHeight();
    height -= 90; // table tools and header, possibly horizontal scrollbar

    var rp = Math.floor(height / 26);
    console.log(rp);
    return rp;
}

function create_flexigrid(domid, options) {
    current_grid = domid;
    if (grids[domid] == null) {
        // grid doesn't exist yet, so create it
        var me = jQuery('#' + domid);
        var rp = calculate_flexigrid_rp(me.parents('.resize,.ui-tabs-panel'));
        grids[domid] = me.flexigrid(jQuery.extend({}, flexigrid_defaults, texts.flexigrid, options, { rp: rp }));
        jQuery('*[title]').tipsy({ opacity: 1, delayIn: 500, gravity: 's' });
    } else {
        // grid does exist, make sure it has the right size
        var grid = grids[domid][0].grid;
        var oldrp = grid.getRp();
        var rp = calculate_flexigrid_rp(jQuery(grids[domid][0]).parents('.resize,.ui-tabs-panel'));
        if (rp != oldrp) {
            grid.newRp(rp);
            grid.fixHeight();
        }
    }
}

var create_flexigrid_for = {
    keys: {
        keys: function() {
            create_flexigrid('grid-keys', {
                url: '/api/2/db/keys?include=prevalent_values',
                colModel: [
                    { display: texts.osm.key, name: 'key', width: 160, sortable: true },
                    { display: '<span title="Number of objects with this key"><img src="/img/types/all.16.png" alt=""/> Total</span>',           name: 'count_all',        width: 200, sortable: true, align: 'center' },
                    { display: '<span title="Number of nodes with this key"><img src="/img/types/node.16.png" alt=""/> Nodes</span>',            name: 'count_nodes',      width: 220, sortable: true, align: 'center' },
                    { display: '<span title="Number of ways with this key"><img src="/img/types/way.16.png" alt=""/> Ways</span>',               name: 'count_ways',       width: 220, sortable: true, align: 'center' },
                    { display: '<span title="Number of relations with this key"><img src="/img/types/relation.16.png" alt=""/> Relation</span>', name: 'count_relations',  width: 220, sortable: true, align: 'center' },
                    { display: '<span title="Number of users currently owning objects with this key">Users</span>', name: 'users_all', width: 44, sortable: true, align: 'right' },
                    { display: '<img src="/img/sources/wiki.16.png" alt="Wiki" title="Key has wiki page"/>', name: 'in_wiki', width: 20, sortable: true, align: 'center' },
                    { display: '<img src="/img/sources/josm.16.png" alt="JOSM" title="Key appears in JOSM config"/>', name: 'in_josm', width: 20, sortable: true, align: 'center' },
                    { display: '<span title="Number of different values for this key">Values</span>', name: 'values_all', width: 70, sortable: true, align: 'right' },
                    { display: 'Prevalent Values', name: 'prevalent_values', width: 500, sortable: true }
                ],
                searchitems: [
                    { display: texts.osm.key, name: 'key' }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            link_to_key(row.key),
                            print_value_with_percent(row.count_all,       row.count_all_fraction),
                            print_value_with_percent(row.count_nodes,     row.count_nodes_fraction),
                            print_value_with_percent(row.count_ways,      row.count_ways_fraction),
                            print_value_with_percent(row.count_relations, row.count_relations_fraction),
                            print_with_ts(row.users_all),
                            row.in_wiki ? '&#x2714;' : '-',
                            row.in_josm ? '&#x2714;' : '-',
                            print_with_ts(row.values_all),
                            print_prevalent_value_list(row.key, row.prevalent_values)
                        ] };
                    });
                    return data;
                }
            });
        }
    },
    tags: {
        tags: function() {
            create_flexigrid('grid-tags', {
                url: '/api/2/db/tags',
                colModel: [
                    { display: texts.osm.tag, name: 'tag', width: 300, sortable: true },
                    { display: '<span title="Number of objects with this tag"><img src="/img/types/all.16.png" alt=""/> Total</span>',           name: 'count_all',        width: 260, sortable: true, align: 'center' },
                    { display: '<span title="Number of nodes with this tag"><img src="/img/types/node.16.png" alt=""/> Nodes</span>',            name: 'count_nodes',      width: 220, sortable: true, align: 'center' },
                    { display: '<span title="Number of ways with this tag"><img src="/img/types/way.16.png" alt=""/> Ways</span>',               name: 'count_ways',       width: 220, sortable: true, align: 'center' },
                    { display: '<span title="Number of relations with this tag"><img src="/img/types/relation.16.png" alt=""/> Relation</span>', name: 'count_relations',  width: 220, sortable: true, align: 'center' }
                ],
                searchitems: [
                    { display: texts.osm.tag, name: 'tag' }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            '<span class="overflow">' + link_to_tag(row.key, row.value) + '</span>',
                            print_value_with_percent(row.count_all,       row.count_all_fraction),
                            print_value_with_percent(row.count_nodes,     row.count_nodes_fraction),
                            print_value_with_percent(row.count_ways,      row.count_ways_fraction),
                            print_value_with_percent(row.count_relations, row.count_relations_fraction)
                        ] };
                    });
                    return data;
                }
            });
        }
    },
    tag: {
        overview: function(key, value, filter_type) {
            create_flexigrid('grid-overview', {
                url: '/api/3/db/tags/overview?key=' + encodeURIComponent(key) + '&value=' + encodeURIComponent(value),
                colModel: [
                    { display: 'Type', name: 'type', width: 100, sortable: true },
                    { display: 'Number of objects', name: 'count', width: 260, sortable: true, align: 'center' }
                ],
                usepager: false,
                useRp: false,
                preProcess: function(data) {
                    return {
                        total: 4,
                        page: 1,
                        rows: jQuery.map(data, function(row, i) {
                            return { 'cell': [
                                print_image(row.type) + ' ' + texts.osm[row.type],
                                print_value_with_percent(row.count, row.count_fraction)
                            ]};
                        })
                    };
                }
            });
        },
        combinations: function(key, value, filter_type) {
            create_flexigrid('grid-combinations', {
                url: '/api/2/db/tags/combinations?key=' + encodeURIComponent(key) + '&value=' + encodeURIComponent(value) + '&filter=' + encodeURIComponent(filter_type),
                colModel: [
                    { display: '<span title="Number of objects with this tag that also have the other tag">' + texts.misc.count + ' &rarr;</span>', name: 'to_count', width: 320, sortable: true, align: 'center' },
                    { display: '<span title="Tag used together with this tag">' + texts.pages.tag.other_tags_used.other + '</span>', name: 'other_tag', width: 340, sortable: true },
                    { display: '<span title="Number of objects with other tag that also have this tag">&rarr; ' + texts.misc.count + '</span>', name: 'from_count', width: 320, sortable: true, align: 'center' }
                ],
                searchitems: [
                    { display: 'Other tag', name: 'other_tag' }
                ],
                sortname: 'to_count',
                sortorder: 'desc',
                emptymsg: 'No combinations found (only checked the most common ones).',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            print_value_with_percent(row.together_count, row.to_fraction),
                            link_to_key_or_tag(row.other_key, row.other_value),
                            print_value_with_percent(row.together_count, row.from_fraction),
                        ] };
                    });
                    return data;
                }
            });
        },
        wiki: function(key, value) {
            create_flexigrid('grid-wiki', {
                url: '/api/2/wiki/tags?key=' + encodeURIComponent(key) + '&value=' + encodeURIComponent(value),
                colModel: [
                    { display: 'Language',      name: 'lang',             width: 150, sortable: false },
                    { display: 'Wiki page',     name: 'title',            width: 200, sortable: false, align: 'right' },
                    { display: 'Description',   name: 'description',      width: 400, sortable: false },
                    { display: 'Image',         name: 'image',            width: 120, sortable: false },
                    { display: 'Objects',       name: 'objects',          width:  80, sortable: false },
                    { display: 'Implied Tags',  name: 'tags_implied',     width: 120, sortable: false },
                    { display: 'Combined Tags', name: 'tags_combination', width: 120, sortable: false },
                    { display: 'Linked Tags',   name: 'tags_linked',      width: 220, sortable: false }
                ],
                usepager: false,
                useRp: false,
                preProcess: function(data) {
                    return {
                        total: data.size,
                        page: 1,
                        rows: jQuery.map(data, function(row, i) {
                            return { 'cell': [
                                print_language(row.lang, row.language, row.language_en),
                                print_wiki_link(row.title),
                                row.description,
                                row.image == ''   ? empty(texts.misc.no_image) : hover_expand(print_wiki_link(row.image)),
                                (row.on_node      ? '<img src="/img/types/node.16.png"     alt="yes"/>' : '<img src="/img/types/none.16.png" alt="no"/>') + ' ' +
                                (row.on_way       ? '<img src="/img/types/way.16.png"      alt="yes"/>' : '<img src="/img/types/none.16.png" alt="no"/>') + ' ' +
                                (row.on_area      ? '<img src="/img/types/area.16.png"     alt="yes"/>' : '<img src="/img/types/none.16.png" alt="no"/>') + ' ' +
                                (row.on_relation  ? '<img src="/img/types/relation.16.png" alt="yes"/>' : '<img src="/img/types/none.16.png" alt="no"/>'),
                                print_key_or_tag_list(row.tags_implies),
                                print_key_or_tag_list(row.tags_combination),
                                print_key_or_tag_list(row.tags_linked)
                            ]};
                        })
                    };
                }
            });
        },
        josm: function(key, value) {
            create_flexigrid('grid-josm', {
                url: '/api/2/josm/styles/standard/tags?key=' + encodeURIComponent(key) + '&value=' + encodeURIComponent(value),
                colModel: [
                    { display: texts.osm.value, name: 'v',    width: 400, sortable: false },
                    { display: 'Icon', name: 'icon', width: 30, sortable: false, align: 'center' },
                    { display: 'Line', name: 'line', width: 30, sortable: false, align: 'center' },
                    { display: 'Area', name: 'area', width: 30, sortable: false, align: 'center' }
                ],
                sortname: 'v',
                sortorder: 'asc',
                emptymsg: 'No JOSM styles for this tag.',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            row.v ? link_to_value(row.k, row.v) : row.b ? (row.b + ' (Boolean)') : '*',
                            row.icon ? '<img src="/api/2/josm/styles/images?style=standard&image=' + row.icon + '" title="' + row.icon + '" alt=""/>' : '',
                            '<div>' + (row.line_width > 0 ? '<div title="' + row.line_color + '" style="height: ' + row.line_width + 'px; margin-top: ' + (10 - Math.round(row.line_width/2)) + 'px; padding: 0; background-color: ' + row.line_color + '"></div>' : '') + '</div>',
                            row.area_color ? '<div title="' + row.area_color + '" style="height: 18px; background-color: ' + row.area_color + '"></div>' : ''
                        ] };
                    });
                    return data;
                }
            });
        }
    },
    key: {
        overview: function(key, filter_type) {
            create_flexigrid('grid-overview', {
                url: '/api/3/db/keys/overview?key=' + encodeURIComponent(key),
                colModel: [
                    { display: 'Type', name: 'type', width: 100, sortable: true },
                    { display: 'Number of objects', name: 'count', width: 260, sortable: true, align: 'center' },
                    { display: 'Number of values', name: 'value', width: 140, sortable: true, align: 'right' }
                ],
                usepager: false,
                useRp: false,
                preProcess: function(data) {
                    return {
                        total: 4,
                        page: 1,
                        rows: jQuery.map(data, function(row, i) {
                            return { 'cell': [
                                print_image(row.type) + ' ' + texts.osm[row.type],
                                print_value_with_percent(row.count, row.count_fraction),
                                print_with_ts(row.values)
                            ]};
                        })
                    };
                }
            });
        },
        values: function(key, filter_type) {
            create_flexigrid('grid-values', {
                url: '/api/2/db/keys/values?key=' + encodeURIComponent(key) + '&filter=' + encodeURIComponent(filter_type),
                colModel: [
                    { display: texts.osm.value, name: 'value', width: 500, sortable: true },
                    { display: texts.misc.count, name: 'count', width: 300, sortable: true, align: 'center' }
                ],
                searchitems: [
                    { display: texts.osm.value, name: 'value' }
                ],
                sortname: 'count',
                sortorder: 'desc',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            link_to_value(key, row.value),
                            print_value_with_percent(row.count, row.fraction)
                        ] };
                    });
                    delete data.data;
                    return data;
                }
            });
        },
        keys: function(key, filter_type) {
            create_flexigrid('grid-keys', {
                url: '/api/2/db/keys/keys?key=' + encodeURIComponent(key) + '&filter=' + encodeURIComponent(filter_type),
                colModel: [
                    { display: '<span title="Number of objects with this key that also have the other key">' + texts.misc.count + ' &rarr;</span>', name: 'to_count', width: 320, sortable: true, align: 'center' },
                    { display: '<span title="Key used together with this key">' + texts.pages.key.other_keys_used.other + '</span>', name: 'other_key', width: 340, sortable: true },
                    { display: '<span title="Number of objects with other key that also have this key">&rarr; ' + texts.misc.count + '</span>', name: 'from_count', width: 320, sortable: true, align: 'center' }
                ],
                searchitems: [
                    { display: 'Other key', name: 'other_key' }
                ],
                sortname: 'to_count',
                sortorder: 'desc',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            print_value_with_percent(row.together_count, row.to_fraction),
                            link_to_key(row.other_key),
                            print_value_with_percent(row.together_count, row.from_fraction),
                        ] };
                    });
                    return data;
                }
            });
        },
        josm: function(key, filter_type) {
            create_flexigrid('grid-josm', {
                url: '/api/2/josm/styles/standard/keys?key=' + encodeURIComponent(key),
                colModel: [
                    { display: texts.osm.value, name: 'v', width: 400, sortable: true },
                    { display: 'Icon', name: 'icon', width: 30, sortable: false, align: 'center' },
                    { display: 'Line', name: 'line', width: 30, sortable: false, align: 'center' },
                    { display: 'Area', name: 'area', width: 30, sortable: false, align: 'center' }
                ],
                sortname: 'v',
                sortorder: 'asc',
                emptymsg: 'No JOSM styles for this key.',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            row.v ? link_to_value(row.k, row.v) : row.b ? (row.b + ' (Boolean)') : '*',
                            row.icon ? '<img src="/api/2/josm/styles/images?style=standard&image=' + row.icon + '" title="' + row.icon + '" alt=""/>' : '',
                            '<div>' + (row.line_width > 0 ? '<div title="' + row.line_color + '" style="height: ' + row.line_width + 'px; margin-top: ' + (10 - Math.round(row.line_width/2)) + 'px; padding: 0; background-color: ' + row.line_color + '"></div>' : '') + '</div>',
                            row.area_color ? '<div title="' + row.area_color + '" style="height: 18px; background-color: ' + row.area_color + '"></div>' : ''
                        ] };
                    });
                    return data;
                }
            });
        },
        wiki: function(key, filter_type) {
            create_flexigrid('grid-wiki', {
                url: '/api/2/wiki/keys?key=' + encodeURIComponent(key),
                colModel: [
                    { display: 'Language',      name: 'lang',             width: 150, sortable: false },
                    { display: 'Wiki page',     name: 'title',            width: 160, sortable: false, align: 'right' },
                    { display: 'Description',   name: 'description',      width: 400, sortable: false },
                    { display: 'Image',         name: 'image',            width: 120, sortable: false },
                    { display: 'Objects',       name: 'objects',          width:  80, sortable: false },
                    { display: 'Implied Tags',  name: 'tags_implied',     width: 120, sortable: false },
                    { display: 'Combined Tags', name: 'tags_combination', width: 120, sortable: false },
                    { display: 'Linked Tags',   name: 'tags_linked',      width: 220, sortable: false }
                ],
                usepager: false,
                useRp: false,
                preProcess: function(data) {
                    return {
                        total: data.size,
                        page: 1,
                        rows: jQuery.map(data, function(row, i) {
                            return { 'cell': [
                                print_language(row.lang, row.language, row.language_en),
                                print_wiki_link(row.title),
                                row.description,
                                row.image == ''   ? empty(texts.misc.no_image) : hover_expand(print_wiki_link(row.image)),
                                (row.on_node      ? '<img src="/img/types/node.16.png"     alt="yes" width="16" height="16"/>' : '<img src="/img/types/none.16.png" alt="no" width="16" height="16"/>') + ' ' +
                                (row.on_way       ? '<img src="/img/types/way.16.png"      alt="yes" width="16" height="16"/>' : '<img src="/img/types/none.16.png" alt="no" width="16" height="16"/>') + ' ' +
                                (row.on_area      ? '<img src="/img/types/area.16.png"     alt="yes" width="16" height="16"/>' : '<img src="/img/types/none.16.png" alt="no" width="16" height="16"/>') + ' ' +
                                (row.on_relation  ? '<img src="/img/types/relation.16.png" alt="yes" width="16" height="16"/>' : '<img src="/img/types/none.16.png" alt="no" width="16" height="16"/>'),
                                print_key_or_tag_list(row.tags_implies),
                                print_key_or_tag_list(row.tags_combination),
                                print_key_or_tag_list(row.tags_linked)
                            ]};
                        })
                    };
                }
            });
        }
    },
    search: {
        keys: function(query) {
            create_flexigrid('grid-keys', {
                url: '/api/2/db/keys?query=' + encodeURIComponent(query),
                colModel: [
                    { display: texts.misc.count, name: 'count_all', width: 80, sortable: true, align: 'right' },
                    { display: texts.osm.key, name: 'key', width: 500, sortable: true }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            print_with_ts(row.count_all),
                            link_to_key_with_highlight(row.key, query)
                        ] };
                    });
                    return data;
                }
            });
        },
        values: function(query) {
            create_flexigrid('grid-values', {
                url: '/api/2/search/values?q=' + encodeURIComponent(query),
                colModel: [
                    { display: texts.misc.count, name: 'count_all', width: 80, sortable: true, align: 'right' },
                    { display: texts.osm.key, name: 'key', width: 250, sortable: true },
                    { display: texts.osm.value, name: 'value', width: 500, sortable: true }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            print_with_ts(row.count_all),
                            link_to_key(row.key),
                            link_to_value_with_highlight(row.key, row.value, query)
                        ] };
                    });
                    return data;
                }
            });
        },
        tags: function(query) {
            var q = query.split('=', 2);
            create_flexigrid('grid-tags', {
                url: '/api/2/search/tags?q=' + encodeURIComponent(query),
                colModel: [
                    { display: texts.misc.count, name: 'count_all', width: 80, sortable: true, align: 'right' },
                    { display: texts.osm.key, name: 'key', width: 300, sortable: true },
                    { display: texts.osm.value, name: 'value', width: 500, sortable: true }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            print_with_ts(row.count_all),
                            link_to_key_with_highlight(row.key, q[0]),
                            link_to_value_with_highlight(row.key, row.value, q[1])
                        ] };
                    });
                    return data;
                }
            });
        },
        wiki: function(query) {
            // TODO
        }
    },
    reports: {
        josm_styles: function(stylename) {
            create_flexigrid('grid-rules', {
                url: '/api/2/josm/styles/' + stylename,
                colModel: [
                    { display: texts.osm.key,   name: 'k', width: 300, sortable: true },
                    { display: texts.osm.value, name: 'v', width: 300, sortable: true },
                    { display: 'Icon', name: 'icon', width: 30, sortable: false, align: 'center' },
                    { display: 'Line', name: 'line', width: 30, sortable: false, align: 'center' },
                    { display: 'Area', name: 'area', width: 30, sortable: false, align: 'center' }
                ],
                searchitems: [
                    { display: 'Key/Value', name: 'k' }
                ],
                sortname: 'k',
                sortorder: 'asc',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            link_to_key(row.k),
                            row.v ? link_to_value(row.k, row.v) : row.b ? (row.b + ' (Boolean)') : '*',
                            row.icon ? '<img src="/api/2/josm/styles/images?style=standard&image=' + row.icon + '" title="' + row.icon + '" alt=""/>' : '',
                            '<div>' + (row.line_width > 0 ? '<div title="' + row.line_color + '" style="height: ' + row.line_width + 'px; margin-top: ' + (10 - Math.round(row.line_width/2)) + 'px; padding: 0; background-color: ' + row.line_color + '"></div>' : '') + '</div>',
                            row.area_color ? '<div title="' + row.area_color + '" style="height: 18px; background-color: ' + row.area_color + '"></div>' : ''
                        ] };
                    });
                    return data;
                }
            });
        },
        wiki_pages_about_non_existing_keys: function() {
            create_flexigrid('grid-keys', {
                url: '/api/2/db/keys?filters=in_wiki,not_in_db&include=wikipages',
                colModel: [
                    { display: '<img src="/img/sources/wiki.16.png" alt="Wiki" title="Wiki"/>', name: 'in_wiki', width: 20, sortable: true, align: 'center' },
                    { display: '<img src="/img/sources/josm.16.png" alt="JOSM" title="JOSM"/>', name: 'in_josm', width: 20, sortable: true, align: 'center' },
                //   { display: '<img src="/img/sources/potlatch.16.png" alt="Potlatch 2" title="Potlatch 2"/>', name: 'in_potlatch', width: 20, sortable: true, align: 'center' },
                //   { display: '<img src="/img/sources/merkaartor.16.png" alt="Merkaartor" title="Merkaartor"/>', name: 'in_merkaartor', width: 20, sortable: true, align: 'center' },
                    { display: texts.osm.key, name: 'key', width: 260, sortable: true, align: 'left' },
                    { display: 'Wiki Pages', name: 'wikipages', width: 400, sortable: false, align: 'left' }
                ],
                searchitems: [
                    { display: texts.osm.key, name: 'key' }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        var wikilinks = [];
                        jQuery(row.wikipages).each(function(i, wikipage) {
                            wikilinks.push(print_wiki_link(wikipage.title));
                        });
                        return { 'cell': [
                            row.in_wiki       ? '&#x2714;' : '-',
                            row.in_josm       ? '&#x2714;' : '-',
                    //       row.in_potlatch   ? '&#x2714;' : '-',
                    //       row.in_merkaartor ? '&#x2714;' : '-',
                            link_to_key(row.key),
                            wikilinks.join(' &nbsp;&bull;&nbsp; ')
                        ] };
                    });
                    return data;
                }
            });
        },
        languages: function() {
            create_flexigrid('grid-langs', {
                url: '/api/2/reports/languages',
                colModel: [
                    { display: 'Code', name: 'code', width: 60, sortable: true },
                    { display: 'Native Name', name: 'native_name', width: 150, sortable: true },
                    { display: 'English Name', name: 'english_name', width: 150, sortable: true },
                    { display: 'Wiki Key Pages', name: 'wiki_key_pages', width: 260, sortable: true, align: 'center' },
                    { display: 'Wiki Tag Pages', name: 'wiki_tag_pages', width: 260, sortable: true, align: 'center' }
                ],
                sortname: 'code',
                sortorder: 'asc',
                showToggleBtn: false,
                usepager: false,
                useRp: false,
                preProcess: function(data) {
                    return {
                        total: data.total,
                        page: 1,
                        rows: jQuery.map(data.data, function(row, i) {
                            return { 'cell': [
                                '<span class="lang">' + row.code + '</span"',
                                row.native_name,
                                row.english_name,
                                print_value_with_percent(row.wiki_key_pages, row.wiki_key_pages_fraction),
                                print_value_with_percent(row.wiki_tag_pages, row.wiki_tag_pages_fraction)
                            ]};
                        })
                    };
                }
            });
        },
        frequently_used_keys_without_wiki_page: function(english) {
            create_flexigrid('grid-keys', {
                url: '/api/2/reports/frequently_used_keys_without_wiki_page?english=' + english,
                colModel: [
                    { display: 'Create Wiki Page...', name: 'create_wiki_page', width: 200, sortable: false },
                    { display: texts.osm.key, name: 'key', width: 180, sortable: true },
                    { display: '<span title="Number of objects with this key">Total</span>', name: 'count_all', width: 70, sortable: true, align: 'right' },
                    { display: 'Users', name: 'users_all', width: 44, sortable: true, align: 'right' },
                    { display: '<span title="Number of different values for this key">Values</span>', name: 'values_all', width: 70, sortable: true, align: 'right' },
                    { display: 'Prevalent Values', name: 'prevalent_values', width: 500, sortable: true }
                ],
                searchitems: [
                    { display: texts.osm.key, name: 'key' }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            print_wiki_link('Key:' + row.key, { edit: true }),
                            link_to_key(row.key),
                            print_with_ts(row.count_all),
                            print_with_ts(row.users_all),
                            print_with_ts(row.values_all),
                            print_prevalent_value_list(row.key, row.prevalent_values)
                        ] };
                    });
                    return data;
                }
            });
        },
        characters_in_keys: {
            whitespace: function() {
                create_flexigrid('grid-whitespace', {
                    url: '/api/2/db/keys?filters=characters_space&include=prevalent_values',
                    colModel: [
                        { display: texts.osm.key, name: 'key', width: 250, sortable: true },
                        { display: '<span title="Number of objects with this key"><img src="/img/types/all.16.png" alt=""/> Total</span>',           name: 'count_all',        width: 250, sortable: true, align: 'center' },
                        { display: 'Users', name: 'users_all', width: 44, sortable: true, align: 'right' },
                        { display: '<img src="/img/sources/wiki.16.png" alt="Wiki" title="Wiki"/>', name: 'in_wiki', width: 20, sortable: true, align: 'center' },
                        { display: '<img src="/img/sources/josm.16.png" alt="JOSM" title="JOSM"/>', name: 'in_josm', width: 20, sortable: true, align: 'center' },
                        //   { display: '<img src="/img/sources/potlatch.16.png" alt="Potlatch 2" title="Potlatch 2"/>', name: 'in_potlatch', width: 20, sortable: true, align: 'center' },
                        //   { display: '<img src="/img/sources/merkaartor.16.png" alt="Merkaartor" title="Merkaartor"/>', name: 'in_merkaartor', width: 20, sortable: true, align: 'center' },
                        { display: '<span title="Number of different values for this key">Values</span>', name: 'values_all', width: 70, sortable: true, align: 'right' },
                        { display: 'Prevalent Values', name: 'prevalent_values', width: 500, sortable: true }
                    ],
                    searchitems: [
                        { display: texts.osm.key, name: 'key' }
                    ],
                    sortname: 'count_all',
                    sortorder: 'desc',
                    preProcess: function(data) {
                        data.rows = jQuery.map(data.data, function(row, i) {
                            return { 'cell': [
                                link_to_key(row.key),
                                print_value_with_percent(row.count_all,       row.count_all_fraction),
                                print_with_ts(row.users_all),
                                row.in_wiki       ? '&#x2714;' : '-',
                                row.in_josm       ? '&#x2714;' : '-',
                            //       row.in_potlatch   ? '&#x2714;' : '-',
                            //       row.in_merkaartor ? '&#x2714;' : '-',
                                print_with_ts(row.values_all),
                                print_prevalent_value_list(row.key, row.prevalent_values)
                            ] };
                        });
                        return data;
                    }
                });
            },
            problematic: function() {
                create_flexigrid('grid-problematic', {
                    url: '/api/2/db/keys?filters=characters_problematic&include=prevalent_values',
                    colModel: [
                        { display: texts.osm.key, name: 'key', width: 250, sortable: true },
                        { display: '<span title="Number of objects with this key"><img src="/img/types/all.16.png" alt=""/> Total</span>',           name: 'count_all',        width: 250, sortable: true, align: 'center' },
                        { display: 'Users', name: 'users_all', width: 44, sortable: true, align: 'right' },
                        { display: '<img src="/img/sources/wiki.16.png" alt="Wiki" title="Wiki"/>', name: 'in_wiki', width: 20, sortable: true, align: 'center' },
                        { display: '<img src="/img/sources/josm.16.png" alt="JOSM" title="JOSM"/>', name: 'in_josm', width: 20, sortable: true, align: 'center' },
                        //   { display: '<img src="/img/sources/potlatch.16.png" alt="Potlatch 2" title="Potlatch 2"/>', name: 'in_potlatch', width: 20, sortable: true, align: 'center' },
                        //   { display: '<img src="/img/sources/merkaartor.16.png" alt="Merkaartor" title="Merkaartor"/>', name: 'in_merkaartor', width: 20, sortable: true, align: 'center' },
                        { display: '<span title="Number of different values for this key">Values</span>', name: 'values_all', width: 70, sortable: true, align: 'right' },
                        { display: 'Prevalent Values', name: 'prevalent_values', width: 500, sortable: true }
                    ],
                    searchitems: [
                        { display: texts.osm.key, name: 'key' }
                    ],
                    sortname: 'count_all',
                    sortorder: 'desc',
                    preProcess: function(data) {
                        data.rows = jQuery.map(data.data, function(row, i) {
                            return { 'cell': [
                                link_to_key(row.key),
                                print_value_with_percent(row.count_all,       row.count_all_fraction),
                                print_with_ts(row.users_all),
                                row.in_wiki       ? '&#x2714;' : '-',
                                row.in_josm       ? '&#x2714;' : '-',
                            //       row.in_potlatch   ? '&#x2714;' : '-',
                            //       row.in_merkaartor ? '&#x2714;' : '-',
                                print_with_ts(row.values_all),
                                print_prevalent_value_list(row.key, row.prevalent_values)
                            ] };
                        });
                        return data;
                    }
                });
            }
        },
        key_lengths: {
            keys: function() {
                create_flexigrid('grid-keys', {
                    url: '/api/2/db/keys?include=prevalent_values',
                    colModel: [
                        { display: 'Length', name: 'length', width: 60, sortable: true, align: 'right' },
                        { display: texts.osm.key, name: 'key', width: 180, sortable: true },
                        { display: 'Number of Objects', name: 'count_all', width: 250, sortable: true, align: 'center' },
                        { display: '<img src="/img/sources/wiki.16.png" alt="Wiki" title="Wiki"/>', name: 'in_wiki', width: 20, sortable: true, align: 'center' },
                        { display: '<img src="/img/sources/josm.16.png" alt="JOSM" title="JOSM"/>', name: 'in_josm', width: 20, sortable: true, align: 'center' },
                        //   { display: '<img src="/img/sources/potlatch.16.png" alt="Potlatch 2" title="Potlatch 2"/>', name: 'in_potlatch', width: 20, sortable: true, align: 'center' },
                        //   { display: '<img src="/img/sources/merkaartor.16.png" alt="Merkaartor" title="Merkaartor"/>', name: 'in_merkaartor', width: 20, sortable: true, align: 'center' },
                        { display: '<span title="Number of different values for this key">Values</span>', name: 'values_all', width: 70, sortable: true, align: 'right' },
                        { display: 'Prevalent Values', name: 'prevalent_values', width: 500, sortable: true }
                    ],
                    searchitems: [
                        { display: texts.osm.key, name: 'key' }
                    ],
                    sortname: 'length',
                    sortorder: 'asc',
                    preProcess: function(data) {
                        data.rows = jQuery.map(data.data, function(row, i) {
                            return { 'cell': [
                                row.key.length,
                                link_to_key(row.key),
                                print_value_with_percent(row.count_all,       row.count_all_fraction),
                                row.in_wiki       ? '&#x2714;' : '-',
                                row.in_josm       ? '&#x2714;' : '-',
                            //       row.in_potlatch   ? '&#x2714;' : '-',
                            //       row.in_merkaartor ? '&#x2714;' : '-',
                                print_with_ts(row.values_all),
                                print_prevalent_value_list(row.key, row.prevalent_values)
                            ] };
                        });
                        return data;
                    }
                });
            },
            histogram: function() {
            }
        }
    }
};

