// taginfo.js

// capitalize a string
String.prototype.capitalize = function() {
    return this.substr(0, 1).toUpperCase() + this.substr(1);
}

// print a number as percent value with two digits after the decimal point
Number.prototype.print_as_percent = function() {
    return (this * 100).toFixed(2) + '%';
};

/* ============================ */

var grids = {},
    current_grid = '';

/* ============================ */

function init_tipsy() {
    jQuery('*[tipsy]').each(function(index, obj) {
        obj = jQuery(obj);
        obj.tipsy({ opacity: 1, delayIn: 500, gravity: obj.attr('tipsy') });
    });
    jQuery('*[tipsy_html]').each(function(index, obj) {
        obj = jQuery(obj);
        obj.tipsy({ opacity: 1, delayIn: 500, gravity: obj.attr('tipsy_html'), html: true });
    });
}

function resize_box() {
    var wrapper = jQuery('.resize,.ui-tabs-panel'),
        height = jQuery(window).height();

    height -= jQuery('div#header').outerHeight(true);
    height -= jQuery('div.pre').outerHeight(true);
    height -= jQuery('.ui-tabs-nav').outerHeight(true);
    height -= jQuery('div#footer').outerHeight(true);

    wrapper.outerHeight(height);
}

function resize_grid(the_grid) {
    if (grids[the_grid]) {
        var grid = grids[the_grid][0].grid,
            oldrp = grid.getRp(),
            rp = calculate_flexigrid_rp(jQuery(grids[current_grid][0]).parents('.resize,.ui-tabs-panel'));
        if (rp != oldrp) {
            grid.newRp(rp);
            grid.fixHeight();
        }
    }
}

/* ============================ */

function tag(element, text, attrs) {
    if (attrs === undefined) {
        attrs = {}
    }
    var attributes = '';
    for (var a in attrs) {
        attributes += ' ' + a + '="' + attrs[a] + '"';
    }
    return '<' + element + attributes + '>' + text + '</' + element + '>';
}

function link(url, text, attrs) {
    if (attrs === undefined) {
        attrs = {}
    }
    attrs.href = url;
    return tag('a', text, attrs);
}

function span(text, c) {
    return tag('span', text, { 'class': c });
}

function tt(text, c, title) {
    return tag('tt', text, { 'class': c, 'title': title, 'tipsy': 'w' });
}

function hover_expand(text) {
    return span(text, 'overflow');
}

function img_popup(image) {
    var w = image.width,
        h = image.height,
        max_size = 180,
        thumb = w >= h ? max_size : parseInt(max_size / h * w),
        url = image.thumb_url_prefix + thumb + image.thumb_url_suffix,
        title = html_escape('<div class="img_popup"><img src="' + url + '"/></div>');
    return '<span class="overflow" tipsy_html="s" title="' + title + '">' + print_wiki_link(image.title) + '</span>';
}

function empty(text) {
    return span(text, 'empty');
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

    return link('http://wiki.openstreetmap.org/' + path, title, { target: '_blank', 'class': 'extlink' });
}

function print_language(code, native_name, english_name) {
    return tag('span', code, { 'class': 'lang', title: native_name + ' (' + english_name + ')' }) + ' ' + native_name;
}

function print_type_icon(type, on_or_off) {
     return on_or_off ? '<img src="/img/types/' + type + '.16.png" alt="yes" width="16" height="16"/> ' : '<img src="/img/types/none.16.png" alt="no" width="16" height="16"/> ';
}

function print_josm_value(key, value, value_bool) {
    return value ? link_to_value(key, value) : value_bool ? (value_bool + ' (Boolean)') : '*';
}

function print_josm_icon(style, icon) {
    return icon ? '<img src="/api/4/josm/style/image?style=' + style + '&image=' + icon + '" title="' + icon + '" alt=""/>' : '';
}

function print_josm_line(width, color) {
    return '<div>' + (width > 0 ? '<div title="' + color + '" style="height: ' + width + 'px; margin-top: ' + (10 - Math.round(width/2)) + 'px; padding: 0; background-color: ' + color + '"></div>' : '') + '</div>';
}

function print_josm_area(color) {
    return color ? '<div title="' + color + '" style="height: 18px; background-color: ' + color + '"></div>' : '';
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

function print_checkmark(value) {
    return value ? '&#x2714;' : '-';
}

/* ============================ */

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
        return link_to_value_with_title(key, item.value, '(' + item.fraction.print_as_percent() + ')');
    }).join(' &bull; ');
}

function html_escape(text) {
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function url_for_key(key) {
    var k = encodeURIComponent(key);
    if (key.match(/[=\/]/)) {
        return '/keys/?key=' + k;
    } else {
        return '/keys/' + k;
    }
}

function url_for_tag(key, value) {
    var k = encodeURIComponent(key),
        v = encodeURIComponent(value);
    if (key.match(/[=\/]/) || value.match(/[=\/]/)) {
        return '/tags/?key=' + k + '&value=' + v;
    } else {
        return '/tags/' + k + '=' + v;
    }
}

function link_to_value_with_title(key, value, extra) {
    return link(
        url_for_tag(key, value),
        pp_value(value),
        { title: html_escape(value) + ' ' + extra, tipsy: 'e'}
    );
}

function print_value_with_percent(value, fraction) {
    return '<div class="value">' + print_with_ts(value) +
     '</div><div class="fraction">' + fraction.print_as_percent() +
     '</div><div class="bar" style="width: ' + (fraction*100).toFixed() + 'px;"></div>';
}

var pp_chars = '!"#$%&()*+,/;<=>?@[\\]^`{|}~' + "'";

function pp_key(key) {
    if (key == '') {
        return span(texts.misc.empty_string, 'badchar empty');
    }

    var result = '',
        length = key.length;

    for (var i=0; i<length; i++) {
        var c = key.charAt(i);
        if (pp_chars.indexOf(c) != -1) {
            result += span(c, 'badchar');
        } else if (c == ' ') {
            result += span('&#x2423;', 'badchar');
        } else if (c.match(/\s/)) {
            result += span('&nbsp;', 'whitespace');
        } else {
            result += c;
        }
    }

    return result;
}

function pp_value_replace(value) {
    return value.replace(/ /g, '&#x2423;').replace(/\s/g, span('&nbsp;', 'whitespace'));
}

function pp_value(value) {
    if (value == '') {
        return span(texts.misc.empty_string, 'badchar empty');
    }
    return pp_value_replace(value);
}

function link_to_key(key, highlight) {
    return link(
        url_for_key(key),
        highlight === undefined ?
            pp_key(key) : 
            key.replace(new RegExp('(' + highlight + ')', 'gi'), "<b>$1</b>")
    );
}

function link_to_value(key, value, highlight) {
    return link(
        url_for_tag(key, value), 
        highlight === undefined ?
            pp_value(value) :
            value.replace(new RegExp('(' + highlight + ')', 'gi'), "<b>$1</b>")
    );
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

/* ============================ */

var flexigrid_defaults = {
    method        : 'GET',
    dataType      : 'json',
    showToggleBtn : false,
    height        : 'auto',
    usepager      : true,
    useRp         : false,
    onSuccess     : function(grid) {
        init_tipsy();
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

    return Math.floor(height / 26);
}

function create_flexigrid(domid, options) {
    current_grid = domid;
    if (grids[domid] == null) {
        // grid doesn't exist yet, so create it
        var me = jQuery('#' + domid),
            rp = calculate_flexigrid_rp(me.parents('.resize,.ui-tabs-panel'));
        grids[domid] = me.flexigrid(jQuery.extend({}, flexigrid_defaults, texts.flexigrid, options, { rp: rp }));
        jQuery('th *[title]').tipsy({ opacity: 1, delayIn: 500, gravity: 's', offset: 3 });
        jQuery('.sDiv input[title]').tipsy({ opacity: 1, delayIn: 500, gravity: 'e' });
    } else {
        // grid does exist, make sure it has the right size
        resize_grid(domid);
    }
}

function init_tabs(params) {
    return jQuery('#tabs').tabs({
        show: function(event, ui) { 
            resize_box();
            if (ui.index != 0 || window.location.hash != '') {
                window.location.hash = ui.tab.hash;
            }
            if (ui.tab.hash.substring(1) in create_flexigrid_for) {
                create_flexigrid_for[ui.tab.hash.substring(1)].apply(this, params);
            }
        }
    });
}

/* ============================ */

function d3_colors() {
    return ["#1f77b4","#aec7e8","#ff7f0e","#ffbb78","#2ca02c","#98df8a","#d62728","#ff9896","#9467bd","#c5b0d5","#8c564b","#c49c94","#e377c2","#f7b6d2","#7f7f7f","#c7c7c7","#bcbd22","#dbdb8d","#17becf","#9edae5"];
}

/* ============================ */

jQuery(document).ready(function() {
    jQuery('#javascriptmsg').remove();

    jQuery('select').customStyle();

    jQuery.getQueryString = (function(a) {
        if (a == "") return {};
        var b = {};
        for (var i = 0; i < a.length; i++) {
            var p=a[i].split('=');
            b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "));
        }
        return b;
    })(window.location.search.substr(1).split('&'));

    init_tipsy();

    resize_box();

    if (typeof page_init === 'function') {
        page_init();
    }

    jQuery('#locale').bind('change', function() {
        jQuery('#url').val(window.location);
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
        resize_grid(current_grid);
    });
});

