// taginfo.js

var grids = {},
    current_grid = '',
    up = function() { window.location = '/'; };

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
    height -= jQuery('#menu').outerHeight(true);
    height -= jQuery('div.pre').outerHeight(true);
    height -= jQuery('.ui-tabs-nav').outerHeight(true);
    height -= jQuery('div#footer').outerHeight(true);

    if (height < 440) {
        height = 440;
    }

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

var bad_chars_for_url = /[.=\/]/;

function url_for_key(key) {
    var k = encodeURIComponent(key);
    if (key.match(bad_chars_for_url)) {
        return '/keys/?key=' + k;
    } else {
        return '/keys/' + k;
    }
}

function url_for_tag(key, value) {
    var k = encodeURIComponent(key),
        v = encodeURIComponent(value);
    if (key.match(bad_chars_for_url) || value.match(bad_chars_for_url)) {
        return '/tags/?key=' + k + '&value=' + v;
    } else {
        return '/tags/' + k + '=' + v;
    }
}

function url_for_rtype(rtype) {
    var t = encodeURIComponent(rtype);
    if (rtype.match(bad_chars_for_url)) {
        return '/relations/?rtype=' + t;
    } else {
        return '/relations/' + t;
    }
}

function url_for_project(id) {
    return '/projects/' + encodeURIComponent(id);
}

function url_for_wiki(title, options) {
    var path = '//wiki.openstreetmap.org/';
    if (options && options.edit) {
        return path + 'w/index.php?action=edit&title=' + encodeURIComponent(title);
    } else {
        return path + 'wiki/' + encodeURIComponent(title);
    }
}

/* ============================ */

var bad_chars_for_keys = '!"#$%&()*+,/;<=>?@[\\]^`{|}~' + "'";
var non_printable = "\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u0008\u0009\u000e\u000f\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001a\u001b\u001c\u001d\u001e\u001f\u0080\u0081\u0082\u0083\u0084\u0085\u0086\u0087\u0088\u0089\u008a\u008b\u008c\u008d\u008f\u0090\u0091\u0092\u0093\u0094\u0095\u0096\u0097\u0098\u0099\u009a\u009b\u009c\u009d\u009f\u200e\u200f";

function translate(str, fn) {
    var result = '';

    for (var i=0; i < str.length; i++) {
        result += fn(str.charAt(i));
    }

    return result;
}

function fmt_key(key) {
    if (key == '') {
        return span(texts.misc.empty_string, 'badchar empty');
    }

    return translate(key, function(c) {
        if (bad_chars_for_keys.indexOf(c) != -1) {
            return span(c, 'badchar');
        } else if (non_printable.indexOf(c) != -1) {
            return span("\ufffd", 'badchar');
        } else if (c == ' ') {
            return span('&#x2423;', 'badchar');
        } else if (c.match(/\s/)) {
            return span('&nbsp;', 'whitespace');
        } else {
            return c;
        }
    });
}

function fmt_value(value) {
    if (value == '') {
        return span(texts.misc.empty_string, 'badchar empty');
    }

    return html_escape(value)
            .replace(/ /g, '&#x2423;')
            .replace(/\s/g, span('&nbsp;', 'whitespace'));
}

function fmt_rtype(rtype) {
    if (rtype == '') {
        return span(texts.misc.empty_string, 'badchar empty');
    }

    return translate(rtype, function(c) {
        if (c == ' ') {
            return span('&#x2423;', 'badchar');
        } else if (c.match(/\s/)) {
            return span('&nbsp;', 'whitespace');
        } else if (c.match(/[a-zA-Z0-9_:]/)) {
            return c;
        } else {
            return span(c, 'badchar');
        }
    });
}

function fmt_role(role) {
    if (role == '') {
        return span(texts.misc.empty_string, 'empty');
    }

    return translate(role, function(c) {
        if (bad_chars_for_keys.indexOf(c) != -1) {
            return span(c, 'badchar');
        } else if (c == ' ') {
            return span('&#x2423;', 'badchar');
        } else if (c.match(/\s/)) {
            return span('&nbsp;', 'whitespace');
        } else {
            return c;
        }
    });
}

/* ============================ */

function link_to_key(key, attr) {
    return link(
        url_for_key(key),
        fmt_key(key),
        attr
    );
}

function link_to_value(key, value, attr) {
    return link(
        url_for_tag(key, value),
        fmt_value(value),
        attr
    );
}

function link_to_tag(key, value, key_attr, value_attr) {
    return link_to_key(key, key_attr) + '=' + link_to_value(key, value, value_attr);
}

function link_to_rtype(rtype, attr) {
    return link(
        url_for_rtype(rtype),
        fmt_rtype(rtype),
        attr
    );
}

function link_to_project(id, name, icon_url, attr) {
    if (icon_url === null) {
        icon_url = '/img/generic_project_icon.png';
    }
    return img({ src: icon_url, width: 16, height: 16, alt: '' }) + ' ' + link(
        url_for_project(id),
        html_escape(name),
        attr
    );
}

function link_to_wiki(title, options) {
    if (title == '') {
        return '';
    }

    return link(
        url_for_wiki(title, options),
        html_escape(title),
        { target: '_blank', 'class': 'extlink' }
    );
}

function link_to_url(url) {
    return link(
        encodeURI(url),
        html_escape(url.replace(/^http:\/\//, '')),
        { target: '_blank', 'class': 'extlink' }
    );
}

function link_to_url_nofollow(url) {
    return link(
        encodeURI(url),
        html_escape(url.replace(/^http:\/\//, '')),
        { target: '_blank', 'class': 'extlink', 'rel': 'nofollow' }
    );
}

function highlight(str, query) {
    return html_escape(str).replace(new RegExp('(' + html_escape(query) + ')', 'gi'), "<b>$1</b>");
}

function link_to_key_with_highlight(key, query) {
    return link(
        url_for_key(key),
        highlight(key, query)
    );
}

function link_to_value_with_highlight(key, value, query) {
    return link(
        url_for_tag(key, value),
        highlight(value, query)
    );
}

function link_to_rtype_with_highlight(rtype, query) {
    return link(
        url_for_rtype(rtype),
        highlight(rtype, query)
    );
}

/* ============================ */

function html_escape(text) {
    return String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function tag(element, text, attrs) {
    var attributes = '';
    if (attrs !== undefined) {
        for (var a in attrs) {
            attributes += ' ' + a + '="' + attrs[a] + '"';
        }
    }
    if (text === null) {
        return '<' + element + attributes + '/>';
    } else {
        return '<' + element + attributes + '>' + text + '</' + element + '>';
    }
}

function style(styles) {
    var css = '';

    for (var s in styles) {
        css += html_escape(s) + ':' + html_escape(styles[s]) + ';';
    }

    return css;
}

function link(url, text, attrs) {
    if (attrs === undefined) {
        attrs = {}
    }
    attrs.href = url;
    return tag('a', text, attrs);
}

function img(attrs) {
    return tag('img', null, attrs);
}

function span(text, c) {
    return tag('span', text, { 'class': c });
}

function empty(text) {
    return span(text, 'empty');
}

function hover_expand(text) {
    return span(text, 'overflow');
}

/* ============================ */

function fmt_wiki_image_popup(image) {
    if (! image.title) {
        return empty(texts.misc.no_image);
    }

    var w = image.width,
        h = image.height,
        max_size = 180,
        thumb_size = w >= h ? max_size : parseInt(max_size / h * w),
        other_size = (w >= h ? parseInt(max_size / w * h) : max_size) + 2,
        url = image.thumb_url_prefix + thumb_size + image.thumb_url_suffix;

    if (w < max_size) {
        url = image.image_url;
    } else {
        w = thumb_size;
        h = other_size;
    }

    return tag('span', link_to_wiki(image.title), {
        'class': 'overflow',
        tipsy_html: 's',
        title: html_escape(tag('div', img({ src: url }), {
            'class': 'img_popup',
            style: style({ width: w + 'px', height: h + 'px' })
        }))
    });
}

function fmt_language(code, native_name, english_name) {
    return tag('span', html_escape(code), {
        'class': 'lang',
        title: html_escape(native_name + ' (' + english_name + ')')
    }) + ' ' + html_escape(native_name);
}

function fmt_type_icon(type, on_or_off) {
    return img({
        src: '/img/types/' + (on_or_off ? encodeURIComponent(type) : 'none') + '.svg',
        alt: on_or_off ? 'yes' : 'no',
        width: 16,
        height: 16
    }) + ' ';
}


function fmt_type_image(type) {
    type = type.replace(/s$/, '');
    var name = html_escape(texts.osm[type]);
    return img({
        src: '/img/types/' + encodeURIComponent(type) + '.svg',
        alt: '[' + name + ']',
        title: name,
        width: 16,
        height: 16
    }) + ' ' + name;
}

// format a number with thousand separator
function fmt_with_ts(value) {
    if (value === null) {
        return '-';
    } else {
        return value.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1&thinsp;');
    }
}

function fmt_as_percent(value) {
    return (value * 100).toFixed(2) + '%';
}

function fmt_checkmark(value) {
    return value ? '&#x2714;' : '-';
}

function fmt_value_with_percent(value, fraction) {
    return tag('div', fmt_with_ts(value), { 'class': 'value' }) +
           tag('div', fmt_as_percent(fraction), { 'class': 'fraction' }) +
           tag('div', '', { 'class': 'bar', style: style({ width: (fraction*100).toFixed() + 'px' }) });
}

function fmt_key_or_tag_list(list) {
    return jQuery.map(list, function(tag, i) {
        if (tag.match(/=/)) {
            var el = tag.split('=', 2);
            return link_to_tag(el[0], el[1]);
        } else {
            return link_to_key(tag);
        }
    }).join(' &bull; ');
}

function fmt_prevalent_value_list(key, list) {
    if (list.length == 0) {
        return empty(texts.misc.values_less_than_one_percent);
    }
    return jQuery.map(list, function(item, i) {
        return link_to_value(key, item.value, { tipsy: 'e', title: fmt_as_percent(item.fraction) });
    }).join(' &bull; ');
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
        jQuery('th *[title]').tipsy({ opacity: 1, delayIn: 500, gravity: 's', offset: 3 });
        jQuery('.sDiv input[title]').tipsy({ opacity: 1, delayIn: 500, gravity: 'e' });
        jQuery('input.qsbox').bind('keydown', function(event) {
            if (event.which == 27) { // esc
                this.blur();
                return false;
            }
            if (event.which == 9) { // tab
                jQuery('input#search').focus();
                return false;
            }
        });
        jQuery('div.bDiv:visible').bind('click', function(event) {
            var row = jQuery(event.target).parents('tr');
            jQuery('div.bDiv:visible tr').removeClass('trOver');
            jQuery(row).addClass('trOver');
        });
    }
};

function calculate_flexigrid_rp(box) {
    var height = box.innerHeight();

    height -= box.children('h2').outerHeight(true);
    height -= box.children('.boxpre').outerHeight(true);
    height -= box.children('.pDiv').outerHeight();
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
    } else {
        // grid does exist, make sure it has the right size
        resize_grid(domid);
    }
}

function init_tabs(params) {
    return jQuery('#tabs').tabs({
        activate: function (event, ui) {
            resize_box();
            var index = ui.newTab.closest("li").index();
            if (index != 0 || window.location.hash != '') {
                window.location.hash = ui.newTab.context.hash;
            }
            if (ui.newTab.context.hash.substring(1) in create_flexigrid_for) {
                create_flexigrid_for[ui.newTab.context.hash.substring(1)].apply(this, params);
            }
        },
        create: function (event, ui) {
            resize_box();
            var index = jQuery(this).tabs("option", "selected"),
                id = jQuery(jQuery(this).children()[index+1]).attr('id');
            if (index != 0 || window.location.hash != '') {
                window.location.hash = id;
            }
            if (id in create_flexigrid_for) {
                create_flexigrid_for[id].apply(this, params);
            }
        }
    });
}

/* ============================ */

function d3_colors() {
    return ["#1f77b4","#aec7e8","#ff7f0e","#ffbb78","#2ca02c","#98df8a","#d62728","#ff9896","#9467bd","#c5b0d5","#8c564b","#c49c94","#e377c2","#f7b6d2","#7f7f7f","#c7c7c7","#bcbd22","#dbdb8d","#17becf","#9edae5"];
}

/* ============================ */

function table_up() {
    var current = jQuery('.trOver:visible');
    if (current.size() > 0) {
        var prev = jQuery('div.bDiv:visible tr.trOver').removeClass('trOver').prev();
        if (prev.size() > 0) {
            prev.addClass('trOver');
        } else {
            jQuery('div.pPrev:visible').click();
        }
    } else {
        jQuery('div.bDiv:visible tr:last').addClass('trOver');
    }
}

function table_down() {
    var current = jQuery('.trOver:visible');
    if (current.size() > 0) {
        var next = jQuery('div.bDiv:visible tr.trOver').removeClass('trOver').next();
        if (next.size() > 0) {
            next.addClass('trOver');
        } else {
            jQuery('div.pNext:visible').click();
        }
    } else {
        jQuery('div.bDiv:visible tr:first').addClass('trOver');
    }
}

function table_right() {
    var current = jQuery('.trOver');
    if (current.size() > 0) {
        var link = current.find('a.pref');
        if (link.size() == 0) {
            link = current.find('a');
        }
        if (link.size() > 0) {
            window.location = link.attr('href');
        }
    }
}

/* ============================ */

function quote_double(text) {
    return text.replace(/["\\]/gm, '\\$&');
}

function level0_editor(overpass_url_prefix, level0_url_prefix, filter, key, value) {
    var query = '["' + quote_double(key);
    if (value !== undefined) {
        query += '"="' + quote_double(value);
    }
    query += '"];'

    if (filter == 'nodes') {
        query = 'node' + query;
    } else if (filter == 'ways') {
        query = 'way' + query + '>;';
    } else if (filter == 'relations') {
        query = 'rel' + query;
    } else {
        query = '(node' + query + 'way' + query + '>;rel' + query + ');';
    }

    var overpass_url = overpass_url_prefix + 'data=' + encodeURIComponent('[out:xml];' + query + 'out meta;');
    var level0_url = level0_url_prefix + 'url=' + encodeURIComponent(overpass_url);
    window.open(level0_url, '_blank');

    return false;
}

/* ============================ */

function open_help() {
    jQuery('#help').dialog({
        modal: true,
        resizable: false,
        title: texts.misc.help,
        minWidth: 800,
        minHeight: 400,
        position: { my: 'top', at: 'top+100' },
        create: function(event, ui) {
            jQuery('#help_tabs').tabs();
        }
    });
    return false;
}

/* ============================ */

function cookies_enabled() {
    var cookieEnabled = (navigator.cookieEnabled) ? true : false;

    if (typeof navigator.cookieEnabled == "undefined" && !cookieEnabled) {
        document.cookie="testcookie";
        cookieEnabled = (document.cookie.indexOf("testcookie") != -1) ? true : false;
    }
    return (cookieEnabled);
}

function get_comparison_list() {
    return jQuery.cookie('taginfo_comparison_list') || [];
}

function set_comparison_list(list) {
    jQuery.cookie('taginfo_comparison_list', list, { expires: 1, path: '/' });
}

function comparison_list_update(key, value) {
    var l = get_comparison_list().length;

    var cl = jQuery('#list option:first').html();
    cl = cl.replace(/([0-9]+)/, String(l));
    jQuery('#list option:first').html(cl);

    if (comparison_list_contains(get_comparison_list(), key, value)) {
        jQuery('#list option:eq(1)').attr('style', 'color: #e0e0e0');
    } else {
        jQuery('#list option:eq(1)').attr('style', '');
    }
    if (l == 0) {
        jQuery('#list option:eq(2)').attr('style', 'color: #e0e0e0');
    } else {
        jQuery('#list option:eq(2)').attr('style', '');
    }
    if (l < 2) {
        jQuery('#list option:eq(3)').attr('style', 'color: #e0e0e0');
    } else {
        jQuery('#list option:eq(3)').attr('style', '');
    }

    jQuery('#list').val('title').change();
}

function comparison_list_item_clean(text) {
    return text === null || text.match(/^[a-zA-Z0-9:_]+$/) !== null;
}

function comparison_list_url(list) {
    var okay = true;
    jQuery.each(list, function(index, item) {
        if (!comparison_list_item_clean(item[0]) ||
            !comparison_list_item_clean(item[1])) {
            okay = false;
        }
    });

    if (okay) {
        return '/compare/' + jQuery.map(list, function(item, i) {
            return item[0] + (item[1] === null ? '' : ('=' + item[1]));
        }).join('/');
    } else {
        var keys = [];
        var values = [];
        jQuery.each(list, function(index, item) {
            keys.push(item[0]);
            values.push(item[1] === null ? '' : item[1]);
        });
        return '/compare/?' + jQuery.param({ 'key': keys, 'value': values });
    }
}

function comparison_list_contains(list, key, value) {
    var contains = false;

    jQuery.each(list, function(index, item) {
        if (item[0] == key && item[1] == value) {
            contains = true;
        }
    });

    return contains;
}

function comparison_list_change(key, value) {
    var list = get_comparison_list(),
        command = jQuery('#list').val();

    if (command == 'title') {
        return true;
    } else if (command == 'add' && !comparison_list_contains(list, key, value)) {
        list.push([key, value]);
        set_comparison_list(list);
    } else if (command == 'clear') {
        set_comparison_list([]);
    } else if (command == 'compare' && list.length >= 2) {
        window.location = comparison_list_url(list);
    }

    comparison_list_update(key, value);
    return false;
}

/* ============================ */

function activate_josm_button() {
    if (jQuery('#josm_button').length != 0) {
        if (window.location.protocol == "https:") {
            var url = jQuery('#josm_button')[0].href.replace('http://localhost:8111/', 'https://localhost:8112/');
            jQuery('#josm_button')[0].href = url;
        }

        jQuery('#josm_button').bind('click', function() {
            var url = jQuery('#josm_button')[0].href;
            jQuery.get(url, function(data) {
                if (data.substring(0, 2) != 'OK') {
                    alert("Problem contacting JOSM. Is it running? Is remote control activated?");
                    console.log("Answer from JOSM: [" + data + "]");
                }
            });
            return false;
        });
    }
}

/* ============================ */

function project_tag_desc(description, icon, url) {
    var out = '';
    if (icon) {
        out += img({src: icon, alt: '', style: 'max-width: 16px; max-height: 16px;'}) + ' ';
    }
    if (description) {
        out += html_escape(description) + ' ';
    }
    if (url) {
        out += '[' + link(url, 'More...', { target: '_blank', 'class': 'extlink' }) + ']'
    }
    return out;
}

/* ============================ */

jQuery(document).ready(function() {
    jQuery('#javascriptmsg').remove();

    jQuery('select').customSelect();

    jQuery('#help_link').bind('click', open_help);

    jQuery.cookie.json = true;

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
        jQuery('#url').val(window.location.pathname);
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

    jQuery(document).bind('keypress', function(event) {
        if (event.ctrlKey || event.altKey || event.metaKey) {
            return;
        }
        if (event.target == document.body) {
            if (event.which >= 49 && event.which <= 57) { // digit
                jQuery("#tabs").tabs("select", event.which - 49);
            } else {
                switch (event.which) {
                    case 63: // ?
                        open_help();
                        break;
                    case 99: // c
                        window.location = comparison_list_url(get_comparison_list());
                        break;
                    case 102: // f
                        jQuery('input.qsbox').focus();
                        break;
                    case 104: // h
                        window.location = '/';
                        break;
                    case 107: // k
                        window.location = '/keys';
                        break;
                    case 112: // p
                        window.location = '/projects';
                        break;
                    case 114: // r
                        window.location = '/relations';
                        break;
                    case 115: // s
                        jQuery('input#search').focus();
                        break;
                    case 116: // t
                        window.location = '/tags';
                        break;
                    case 120: // x
                        window.location = '/reports';
                        break;
                }
            }
        }
    });

    jQuery(document).bind('keyup', function(event) {
        if (event.ctrlKey || event.altKey || event.metaKey) {
            return;
        }
        if (event.target == document.body) {
            switch (event.which) {
                case 36: // home
                    jQuery('div.pFirst:visible').click();
                    break;
                case 33: // page up
                    jQuery('div.pPrev:visible').click();
                    break;
                case 34: // page down
                    jQuery('div.pNext:visible').click();
                    break;
                case 35: // end
                    jQuery('div.pLast:visible').click();
                    break;
                case 37: // arrow left
                    up();
                    break;
                case 38: // arrow up
                    table_up();
                    break;
                case 39: // arrow right
                    table_right();
                    break;
                case 40: // arrow down
                    table_down();
                    break;
            }
        }
    });

    jQuery(document).bind('keydown', function(event) {
        if (event.target == document.body && event.which == 9) {
            jQuery('input#search').focus();
            return false;
        }
    });

    jQuery('input#search').bind('keydown', function(event) {
        if (event.which == 27) { // esc
            this.blur();
            return false;
        }
        if (event.which == 9) { // tab
            jQuery('input.qsbox:visible').focus();
            return false;
        }
    });

    jQuery('#search_form').bind('submit', function(event) {
        return jQuery('input#search').val() != '';
    });

    jQuery('#menu').slicknav({
        prependTo: 'body',
        label: ''
    });

    jQuery(window).resize(function() {
        jQuery('select').trigger('render');
        resize_box();
        resize_grid(current_grid);
    });
});

