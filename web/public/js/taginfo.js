// taginfo.js

function print_wiki_link(title, options) {
    if (title == '') {
        return '';
    }

    if (options && options.edit) {
        path = 'w/index.php?action=edit&title=' + title;
    } else {
        path = 'wiki/' + title;
    }

    return '<img src="/img/link-wiki.gif" alt="" width="14" height="10"/><a class="wikilink" href="http://wiki.openstreetmap.org/' + path + '" target="_blank">' + title + '</a>';
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
        return '<i>all values have less than 1%</i>';
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
    var name = type.capitalize();
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
        return '<span class="badchar empty">empty string</span>';
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
        return '<span class="badchar empty">empty string</span>';
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
    var k = encodeURIComponent(key),
        title = html_escape(key);

    if (key.match(/[=\/]/)) {
        return '<a class="taglink" href="/keys/?key=' + k + '" title="' + title + '">' + pp_key_with_highlight(key, highlight) + '</a>';
    } else {
        return '<a class="taglink" href="/keys/'      + k + '" title="' + title + '">' + pp_key_with_highlight(key, highlight) + '</a>';
    }
}

function link_to_value_with_highlight(key, value, highlight) {
    return '<a class="taglink" href="' + url_to_value(key, value) + '" title="' + html_escape(key) + '=' + html_escape(value) + '">' + pp_value_with_highlight(value, highlight) + '</a>';
}

function html_escape(text) {
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function link_to_key(key) {
    var k = encodeURIComponent(key),
        title = html_escape(key);

    if (key.match(/[=\/]/)) {
        return '<a class="taglink" href="/keys/?key=' + k + '" title="' + title + '">' + pp_key(key) + '</a>';
    } else {
        return '<a class="taglink" href="/keys/'      + k + '" title="' + title + '">' + pp_key(key) + '</a>';
    }
}

function link_to_key_with_highlight(key, highlight) {
    var k = encodeURIComponent(key),
        title = html_escape(key);

    var re = new RegExp('(' + highlight + ')', 'g');
    var hk = key.replace(re, "<b>$1</b>");

    if (key.match(/[=\/]/)) {
        return '<a class="taglink" href="/keys/?key=' + k + '" title="' + title + '">' + hk + '</a>';
    } else {
        return '<a class="taglink" href="/keys/'      + k + '" title="' + title + '">' + hk + '</a>';
    }
}

function link_to_value(key, value) {
    return '<a class="taglink" href="' + url_to_value(key, value) + '" title="' + html_escape(key) + '=' + html_escape(value) + '">' + pp_value(value) + '</a>';
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

jQuery(document).ready(function() {
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
    });
    jQuery('#search').focus();
});

/* ============================ */

var grids = {};

var flexigrid_defaults = {
    method        : 'GET',
    dataType      : 'json',
    showToggleBtn : false,
    usepager      : true,
    useRp         : true,
    rp            : 15,
    rpOptions     : [10,15,20,25,50,100],
};

function create_flexigrid(domid, options) {
    if (grids[domid] == null) {
        grids[domid] = jQuery('#' + domid).flexigrid(jQuery.extend({}, flexigrid_defaults, flexigrid_defaults_lang, options));
    }
}

var create_flexigrid_for = {
    keys: {
        keys: function() {
            create_flexigrid('grid-keys', {
                url: '/api/2/db/keys?include=prevalent_values',
                colModel: [
                    { display: 'Key', name: 'key', width: 180, sortable: true },
                    { display: '<span title="Number of objects with this key"><img src="/img/types/all.16.png" alt=""/> Total</span>',           name: 'count_all',        width: 250, sortable: true, align: 'center' },
                    { display: '<span title="Number of nodes with this key"><img src="/img/types/node.16.png" alt=""/> Nodes</span>',            name: 'count_nodes',      width: 250, sortable: true, align: 'center' },
                    { display: '<span title="Number of ways with this key"><img src="/img/types/way.16.png" alt=""/> Ways</span>',               name: 'count_ways',       width: 250, sortable: true, align: 'center' },
                    { display: '<span title="Number of relations with this key"><img src="/img/types/relation.16.png" alt=""/> Relation</span>', name: 'count_relations',  width: 250, sortable: true, align: 'center' },
                    { display: 'Users', name: 'users_all', width: 44, sortable: true, align: 'right' },
                    { display: '<img src="/img/sources/wiki.16.png" alt="Wiki" title="Wiki"/>', name: 'in_wiki', width: 20, sortable: true, align: 'center' },
                    { display: '<img src="/img/sources/josm.16.png" alt="JOSM" title="JOSM"/>', name: 'in_josm', width: 20, sortable: true, align: 'center' },
                    { display: '<span title="Number of different values for this key">Values</span>', name: 'values_all', width: 70, sortable: true, align: 'right' },
                    { display: 'Prevalent Values', name: 'prevalent_values', width: 500, sortable: true }
                ],
                searchitems: [
                    { display: 'Key', name: 'key' }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                height: 420,
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
    tag: {
        wiki: function(key, value) {
            create_flexigrid('grid-wiki', {
                url: '/api/2/wiki/tags?key=' + encodeURIComponent(key) + '&value=' + encodeURIComponent(value),
                colModel: [
                    { display: 'Language',      name: 'lang',             width: 150, sortable: false },
                    { display: 'Wikipage',      name: 'title',            width: 200, sortable: false, align: 'right' },
                    { display: 'Description',   name: 'description',      width: 400, sortable: false },
                    { display: 'Image',         name: 'image',            width: 120, sortable: false },
                    { display: 'Objects',       name: 'objects',          width:  80, sortable: false },
                    { display: 'Implied Tags',  name: 'tags_implied',     width: 120, sortable: false },
                    { display: 'Combined Tags', name: 'tags_combination', width: 120, sortable: false },
                    { display: 'Linked Tags',   name: 'tags_linked',      width: 220, sortable: false }
                ],
                usepager: false,
                useRp: false,
                height: 300,
                preProcess: function(data) {
                    return {
                        total: data.size,
                        page: 1,
                        rows: jQuery.map(data, function(row, i) {
                            return { 'cell': [
                                print_language(row.lang, row.language, row.language_en),
                                print_wiki_link(row.title),
                                row.description,
                                row.image == null ? '<i>no image</i>' : print_wiki_link(row.image),
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
                    { display: 'Value',    name: 'v',    width: 200, sortable: false },
                    { display: 'Rule XML', name: 'rule', width: 100, sortable: false }
                ],
    /*            searchitems: [
                    { display: 'Key/Value', name: 'k' }
                ],*/
                sortname: 'v',
                sortorder: 'asc',
                height: 300,
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            row.v ? link_to_value(row.k, row.v) : row.b ? (row.b + ' (Boolean)') : '*',
                            '<span title="' + row.rule + '">XML</span>'
                        ] };
                    });
                    return data;
                }
            });
        }
    },
    key: {
        values: function(key, filter_type) {
            create_flexigrid('grid-values', {
                url: '/api/2/db/keys/values?key=' + encodeURIComponent(key) + '&filter=' + encodeURIComponent(filter_type),
                colModel: [
                    { display: 'Count', name: 'count', width: 300, sortable: true, align: 'center' },
                    { display: 'Value', name: 'value', width: 500, sortable: true }
                ],
                searchitems: [
                    { display: 'Value', name: 'value' }
                ],
                sortname: 'count',
                sortorder: 'desc',
                height: 410,
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            print_value_with_percent(row.count, row.fraction),
                            link_to_value(key, row.value)
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
                    { display: '<span title="Number of objects with this key that also have the other key">Count &rarr;</span>', name: 'to_count', width: 320, sortable: true, align: 'center' },
                    { display: '<span title="Key used together with this key">Other key</span>', name: 'other_key', width: 340, sortable: true },
                    { display: '<span title="Number of objects with other key that also have this key">&rarr; Count</span>', name: 'from_count', width: 320, sortable: true, align: 'center' }
                ],
                sortname: 'to_count',
                sortorder: 'desc',
                height: 410,
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
                    { display: 'Value',    name: 'v',    width: 200, sortable: true },
                    { display: 'Rule XML', name: 'rule', width: 100, sortable: false }
                ],
                searchitems: [
                    { display: 'Value', name: 'v' }
                ],
                sortname: 'v',
                sortorder: 'asc',
                height: 410,
                preProcess: function(data) {
                    data.rows = jQuery.map(data.data, function(row, i) {
                        return { 'cell': [
                            row.v ? link_to_value(row.k, row.v) : row.b ? (row.b + ' (Boolean)') : '*',
                            '<span title="' + row.rule + '">XML</span>'
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
                    { display: 'Wikipage',      name: 'title',            width: 160, sortable: false, align: 'right' },
                    { display: 'Description',   name: 'description',      width: 400, sortable: false },
                    { display: 'Image',         name: 'image',            width: 120, sortable: false },
                    { display: 'Objects',       name: 'objects',          width:  80, sortable: false },
                    { display: 'Implied Tags',  name: 'tags_implied',     width: 120, sortable: false },
                    { display: 'Combined Tags', name: 'tags_combination', width: 120, sortable: false },
                    { display: 'Linked Tags',   name: 'tags_linked',      width: 220, sortable: false }
                ],
                usepager: false,
                useRp: false,
                height: 400,
                preProcess: function(data) {
                    return {
                        total: data.size,
                        page: 1,
                        rows: jQuery.map(data, function(row, i) {
                            return { 'cell': [
                                print_language(row.lang, row.language, row.language_en),
                                print_wiki_link(row.title),
                                row.description,
                                row.image == null ? '<i>no image</i>' : print_wiki_link(row.image),
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
                    { display: 'Count', name: 'count_all', width: 80, sortable: true, align: 'right' },
                    { display: 'Key', name: 'key', width: 500, sortable: true }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                height: 420,
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
                    { display: 'Count', name: 'count_all', width: 80, sortable: true, align: 'right' },
                    { display: 'Key', name: 'key', width: 250, sortable: true },
                    { display: 'Value', name: 'value', width: 500, sortable: true }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                height: 420,
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
                    { display: 'Count', name: 'count_all', width: 80, sortable: true, align: 'right' },
                    { display: 'Key', name: 'key', width: 300, sortable: true },
                    { display: 'Value', name: 'value', width: 500, sortable: true }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                height: 420,
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
    sources: {
        josm: {
            style: function(stylename) {
                create_flexigrid('grid-rules', {
                    url: '/api/2/josm/styles/' + stylename,
                    colModel: [
                        { display: 'Key',      name: 'k',    width: 200, sortable: true },
                        { display: 'Value',    name: 'v',    width: 200, sortable: true },
                        { display: 'Rule XML', name: 'rule', width: 100, sortable: false }
                    ],
                    searchitems: [
                        { display: 'Key/Value', name: 'k' }
                    ],
                    sortname: 'k',
                    sortorder: 'asc',
                    height: 400,
                    preProcess: function(data) {
                        data.rows = jQuery.map(data.data, function(row, i) {
                            return { 'cell': [
                                link_to_key(row.k),
                                row.v ? link_to_value(row.k, row.v) : row.b ? (row.b + ' (Boolean)') : '*',
                                '<span title="' + row.rule + '">XML</span>'
                            ] };
                        });
                        return data;
                    }
                });
            }
        }
    },
    reports: {
        frequently_used_keys_without_wiki_page: function(english) {
            create_flexigrid('grid-keys', {
                url: '/api/2/reports/frequently_used_keys_without_wiki_page?english=' + english,
                colModel: [
                    { display: 'Create Wiki Page...', name: 'create_wiki_page', width: 200, sortable: false },
                    { display: 'Key', name: 'key', width: 180, sortable: true },
                    { display: '<span title="Number of objects with this key">Total</span>', name: 'count_all', width: 70, sortable: true, align: 'right' },
                    { display: 'Users', name: 'users_all', width: 44, sortable: true, align: 'right' },
                    { display: '<span title="Number of different values for this key">Values</span>', name: 'values_all', width: 70, sortable: true, align: 'right' },
                    { display: 'Prevalent Values', name: 'prevalent_values', width: 500, sortable: true }
                ],
                searchitems: [
                    { display: 'Key', name: 'key' }
                ],
                sortname: 'count_all',
                sortorder: 'desc',
                height: 420,
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
            statistics: function() {
                create_flexigrid('grid-statistics', {
                    colModel: [
                        { display: '&nbsp;', name: 'row', width: 10, sortable: true, align: 'center' },
                        { display: 'Count', name: 'count', width: 40, sortable: true, align: 'right' },
                        { display: 'Fraction', name: 'fraction', width: 60, sortable: true, align: 'right' },
                        { display: 'Characters in Key', name: 'characters', width: 810, sortable: true }
                    ],
                    width: 990,
                    height: 200,
                    usepager: false
                });
            },
            whitespace: function() {
                create_flexigrid('grid-whitespace', {
                    url: '/api/2/db/keys?filters=characters_space&include=prevalent_values',
                    colModel: [
                        { display: 'Key', name: 'key', width: 250, sortable: true },
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
                        { display: 'Key', name: 'key' }
                    ],
                    sortname: 'count_all',
                    sortorder: 'desc',
                    height: 420,
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
                        { display: 'Key', name: 'key', width: 250, sortable: true },
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
                        { display: 'Key', name: 'key' }
                    ],
                    sortname: 'count_all',
                    sortorder: 'desc',
                    height: 420,
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
                        { display: 'Key', name: 'key', width: 180, sortable: true },
                        { display: 'Number of Objects', name: 'count_all', width: 250, sortable: true, align: 'center' },
                        { display: '<img src="/img/sources/wiki.16.png" alt="Wiki" title="Wiki"/>', name: 'in_wiki', width: 20, sortable: true, align: 'center' },
                        { display: '<img src="/img/sources/josm.16.png" alt="JOSM" title="JOSM"/>', name: 'in_josm', width: 20, sortable: true, align: 'center' },
                        //   { display: '<img src="/img/sources/potlatch.16.png" alt="Potlatch 2" title="Potlatch 2"/>', name: 'in_potlatch', width: 20, sortable: true, align: 'center' },
                        //   { display: '<img src="/img/sources/merkaartor.16.png" alt="Merkaartor" title="Merkaartor"/>', name: 'in_merkaartor', width: 20, sortable: true, align: 'center' },
                        { display: '<span title="Number of different values for this key">Values</span>', name: 'values_all', width: 70, sortable: true, align: 'right' },
                        { display: 'Prevalent Values', name: 'prevalent_values', width: 500, sortable: true }
                    ],
                    searchitems: [
                        { display: 'Key', name: 'key' }
                    ],
                    sortname: 'length',
                    sortorder: 'asc',
                    height: 420,
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

