// taginfo.js

// capitalize a string
String.prototype.capitalize = function() {
    return this.substr(0, 1).toUpperCase() + this.substr(1);
}

/* ============================ */

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

function url_for_wiki(title, options) {
    var path = 'http://wiki.openstreetmap.org/';
    if (options && options.edit) {
        return path + 'w/index.php?action=edit&title=' + encodeURIComponent(title);
    } else {
        return path + 'wiki/' + encodeURIComponent(title);
    }
}

/* ============================ */

var bad_chars_for_keys = '!"#$%&()*+,/;<=>?@[\\]^`{|}~' + "'";

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

    return value
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

function link_to_wiki(title, options) {
    if (title == '') {
        return '';
    }

    return link(
        url_for_wiki(title, options),
        title,
        { target: '_blank', 'class': 'extlink' }
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
        src: '/img/types/' + (on_or_off ? encodeURIComponent(type) : 'none') + '.16.png',
        alt: on_or_off ? 'yes' : 'no',
        width: 16,
        height: 16
    }) + ' ';
}

function fmt_josm_value(key, value, value_bool) {
    return value ? link_to_value(key, value) : value_bool ? (html_escape(value_bool) + ' (Boolean)') : '*';
}

function fmt_josm_icon(style, icon) {
    if (!icon) return '';

    return img({
        src: '/api/4/josm/style/image?style=' + encodeURIComponent(style) + '&image=' + encodeURIComponent(icon),
        title: html_escape(icon),
        alt: ''
    });
}

function fmt_josm_line(width, color) {
    var inner = '';
    if (width > 0) {
        inner = tag('div', '', {
            title: color,
            style: style({ height: width + 'px', 'margin-top': (10 - Math.round(width/2)) + 'px', padding: 0, 'background-color': color })
        });
    }
    return tag('div', inner);
}

function fmt_josm_area(color) {
    if (!color) return '';

    return tag('div', '', {
        title: html_escape(color),
        style: style({ height: '18px', 'background-color': html_escape(color) })
    });
}

function fmt_type_image(type) {
    type = type.replace(/s$/, '');
    var name = html_escape(texts.osm[type]);
    return img({
        src: '/img/types/' + encodeURIComponent(type) + '.16.png',
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
        return link_to_value(key, item.value, { tipsy: 'e', title: '(' + fmt_as_percent(item.fraction) + ')' });
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
            console.log("click", row);
            jQuery('div.bDiv:visible tr').removeClass('trOver');
            jQuery(row).addClass('trOver');
        });
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
    });

    jQuery(document).bind('keyup', function(event) {
        if (event.target == document.body) {
            if (event.which >= 49 && event.which <= 57) { // digit
                jQuery("#tabs").tabs("select", event.which - 49);
            } else {
                switch (event.which) {
        /*            case 63: // ?
                        window.location = '/help';
                        break;*/
                    case 70: // f
                        jQuery('input.qsbox').focus();
                        break;
                    case 72: // h
                        window.location = '/';
                        break;
                    case 75: // k
                        window.location = '/keys';
                        break;
                    case 83: // s
                        jQuery('input#search').focus();
                        break;
                    case 84: // t
                        window.location = '/tags';
                        break;
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

    jQuery(window).resize(function() {
        resize_box();
        resize_grid(current_grid);
    });
});

