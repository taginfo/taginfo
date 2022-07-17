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
    const wrapper = jQuery('.resize,.ui-tabs-panel');
    let height = jQuery(window).height();

    height -= jQuery('header').outerHeight(true);
    height -= jQuery('#menu').outerHeight(true);
    height -= jQuery('div.pre').outerHeight(true);
    height -= jQuery('.ui-tabs-nav').outerHeight(true);
    height -= jQuery('footer').outerHeight(true);

    if (height < 440) {
        height = 440;
    }

    wrapper.outerHeight(height);
}

function resize_grid(the_grid) {
    if (grids[the_grid]) {
        let grid = grids[the_grid][0].grid;
        let oldrp = grid.getRp();
        let rp = calculate_flexigrid_rp(jQuery(grids[current_grid][0]).parents('.resize,.ui-tabs-panel'));
        if (rp != oldrp) {
            grid.newRp(rp);
            grid.fixHeight();
        }
    }
}

/* ============================ */

const bad_chars_for_url = /[.=\/]/;

function url_for_key(key) {
    const k = encodeURIComponent(key);
    if (key.match(bad_chars_for_url)) {
        return '/keys/?key=' + k;
    } else {
        return '/keys/' + k;
    }
}

function url_for_tag(key, value) {
    const k = encodeURIComponent(key);
    const v = encodeURIComponent(value);
    if (key.match(bad_chars_for_url) || value.match(bad_chars_for_url)) {
        return '/tags/?key=' + k + '&value=' + v;
    } else {
        return '/tags/' + k + '=' + v;
    }
}

function url_for_rtype(rtype) {
    const t = encodeURIComponent(rtype);
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
    let path = '//wiki.openstreetmap.org/';

    if (options && options.edit) {
        path += 'w/index.php?action=edit&title=';
    } else {
        path += 'wiki/';
    }

    return path + encodeURIComponent(title);
}

/* ============================ */

const bad_chars_for_keys = '!"#$%&()*+,/;<=>?@[\\]^`{|}~' + "'";
const non_printable = "\u0000\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u0008\u0009\u000e\u000f\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001a\u001b\u001c\u001d\u001e\u001f\u0080\u0081\u0082\u0083\u0084\u0085\u0086\u0087\u0088\u0089\u008a\u008b\u008c\u008d\u008f\u0090\u0091\u0092\u0093\u0094\u0095\u0096\u0097\u0098\u0099\u009a\u009b\u009c\u009d\u009f\u200e\u200f";

function translate(str, fn) {
    let result = '';

    for (var i=0; i < str.length; i++) {
        result += fn(str.charAt(i));
    }

    return result;
}

function fmt_desc(lang, dir, desc) {
    if (desc === null) {
        return '';
    }
    return '<span lang="' + lang + '" dir="' + dir + '">' + html_escape(desc) + '</span>';
}

function fmt_status(status) {
    if (status === null) {
        return '';
    }
    return html_escape(status);
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

function link_to_key_with_tab(key, tab, text) {
    return link(
        url_for_key(key) + '#' + tab,
        text
    );
}

function link_to_tag_with_tab(key, value, tab, text) {
    return link(
        url_for_tag(key, value) + '#' + tab,
        text
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

function link_to_project(id, name) {
    icon_url = '/api/4/project/icon?project=' + id;
    return img({ src: icon_url, width: 16, height: 16, alt: '' }) + ' ' + link(
        url_for_project(id),
        html_escape(name)
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

function set_inner_html_to(id, html) {
    const element = document.getElementById(id);
    if (element) {
        element.innerHTML = html;
    }
}

function html_escape(text) {
    return String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function tag(element, text, attrs) {
    let attributes = '';
    if (attrs !== undefined) {
        for (const a in attrs) {
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
    let css = '';

    for (const s in styles) {
        css += html_escape(s) + ':' + html_escape(styles[s]) + ';';
    }

    return css;
}

function link(url, text, attrs) {
    if (attrs === undefined) {
        attrs = {};
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

    let w = image.width;
    let h = image.height;
    const max_size = 180;
    const thumb_size = w >= h ? max_size : parseInt(max_size / h * w);
    const other_size = (w >= h ? parseInt(max_size / w * h) : max_size) + 2;
    let url = image.thumb_url_prefix + thumb_size + image.thumb_url_suffix;

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

function fmt_language(code, dir, native_name, english_name) {
    return tag('span', html_escape(code), {
        'class': 'badge lang',
        title: html_escape(native_name + ' (' + english_name + ')')
    }) + ' ' +
    tag('span', html_escape(native_name), {
        lang: code,
        dir: dir,
    });
}

function fmt_unicode_code_point(num) {
    return 'U+' + num.toString(16).padStart(4, '0');
}

function fmt_unicode_script(code, name) {
    if (code === null || name === null) {
        return '';
    }
    return tag('span', html_escape(code), {'class' : 'badge unicode-script'}) +
           ' ' +
           tag('span', html_escape(name));
}

function fmt_unicode_general_category(category) {
    if (category === null) {
        return '';
    }
    const names = {
        'C': 'Other',
        'Cc': 'Control',
        'Cf': 'Forma',
        'Cn': 'Unassigned',
        'Co': 'Private Use',
        'Cs': 'Surrogate',
        'L': 'Letter',
        'Ll': 'Lowercase Letter',
        'Lm': 'Modifier Letter',
        'Lo': 'Other Letter',
        'Lt': 'Titlecase Letter',
        'Lu': 'Uppercase Letter',
        'M': 'Mark',
        'Mc': 'Spacing Mark',
        'Me': 'Enclosing Mark',
        'Mn': 'Nonspacing Mark',
        'N': 'Number',
        'Nd': 'Decimal Number',
        'Nl': 'Letter Number',
        'No': 'Other Number',
        'P': 'Punctuation',
        'Pc': 'Connector Punctuation',
        'Pd': 'Dash Punctuation',
        'Pe': 'Close Punctuation',
        'Pf': 'Final Punctuation',
        'Pi': 'Initial Punctuation',
        'Po': 'Other Punctuation',
        'Ps': 'Open Punctuation',
        'S': 'Symbol',
        'Sc': 'Currency Symbol',
        'Sk': 'Modifier Symbol',
        'Sm': 'Math Symbol',
        'So': 'Other Symbol',
        'Z': 'Separator',
        'Zl': 'Line Separator',
        'Zp': 'Paragraph Separator',
        'Zs': 'Space Separator',
    };
    return tag('span', html_escape(category), {'class' : 'badge unicode-gc'}) +
           ' ' + names[category];
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
    const name = html_escape(texts.osm[type]);
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
        return value.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1&#x202f;');
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
    return list.map(function(tag) {
        if (tag.match(/=/)) {
            const el = tag.split('=', 2);
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
    return list.map(function(item) {
        return link_to_value(key, item.value, { tipsy: 'e', title: fmt_as_percent(item.fraction) });
    }).join(' &bull; ');
}

/* ============================ */

const flexigrid_defaults = {
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
            const row = jQuery(event.target).parents('tr');
            jQuery('div.bDiv:visible tr').removeClass('trOver');
            jQuery(row).addClass('trOver');
        });
    }
};

function calculate_flexigrid_rp(box) {
    let height = box.innerHeight();

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
        const me = jQuery('#' + domid);
        const rp = calculate_flexigrid_rp(me.parents('.resize,.ui-tabs-panel'));
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
            const index = ui.newTab.closest("li").index();
            if (index != 0 || window.location.hash != '') {
                window.location.hash = ui.newTab.context.hash;
            }
            if (ui.newTab.context.hash.substring(1) in create_flexigrid_for) {
                create_flexigrid_for[ui.newTab.context.hash.substring(1)].apply(this, params);
            }
        },
        create: function (event, ui) {
            resize_box();
            const index = jQuery(this).tabs("option", "selected");
            const id = jQuery(jQuery(this).children()[index+1]).attr('id');
            if (index != 0 || window.location.hash != '') {
                window.location.hash = id;
            }
            if (id in create_flexigrid_for) {
                create_flexigrid_for[id].apply(this, params);
            }
        }
    });
}

function create_characters_flexigrid(string) {
    return create_flexigrid('grid-characters', {
        url: '/api/4/unicode/characters?string=' + encodeURIComponent(string),
        colModel: [
            { display: texts.unicode.character, name: 'character', width: 20, sortable: true },
            { display: texts.unicode.codepoint, name: 'codepoint', width: 60, sortable: true, align: 'right' },
            { display: texts.unicode.script, name: 'script', width: 100, sortable: true },
            { display: texts.unicode.general_category, name: 'general_category', width: 150, sortable: false },
            { display: texts.unicode.name, name: 'name', width: 600, sortable: false, align: 'left' }
        ],
        preProcess: function(data) {
            data.rows = data.data.map(function(row) {
                return { 'cell': [
                    row.char,
                    link('https://decodeunicode.org/' + fmt_unicode_code_point(row.codepoint), fmt_unicode_code_point(row.codepoint), { target: '_blank', title: 'decodeunicode.org' }),
                    fmt_unicode_script(row.script, row.script_name),
                    fmt_unicode_general_category(row.category),
                    row.name
                ] };
            });
            return data;
        }
    });
}

/* ============================ */

function d3_colors() {
    return ["#1f77b4","#aec7e8","#ff7f0e","#ffbb78","#2ca02c","#98df8a","#d62728","#ff9896","#9467bd","#c5b0d5","#8c564b","#c49c94","#e377c2","#f7b6d2","#7f7f7f","#c7c7c7","#bcbd22","#dbdb8d","#17becf","#9edae5"];
}

/* ============================ */

function table_up() {
    const current = jQuery('.trOver:visible');
    if (current.size() > 0) {
        const prev = jQuery('div.bDiv:visible tr.trOver').removeClass('trOver').prev();
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
    const current = jQuery('.trOver:visible');
    if (current.size() > 0) {
        const next = jQuery('div.bDiv:visible tr.trOver').removeClass('trOver').next();
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
    const current = jQuery('.trOver');
    if (current.size() > 0) {
        const link = current.find('a.pref');
        if (link.size() == 0) {
            link = current.find('a');
        }
        if (link.size() > 0) {
            window.location = link.attr('href');
        }
    }
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

class ComparisonList {

    #list = [];

    constructor(list = []) {
        this.#list = list.map(function(d) {
            if (d.value === undefined) {
                d.value = null;
            }
            return [d.key, d.value];
        });
    }

    load() {
        const tcl = window.sessionStorage.getItem('taginfo_comparison_list');
        this.#list = tcl ? JSON.parse(tcl) : [];
    }

    store() {
        window.sessionStorage.setItem('taginfo_comparison_list', JSON.stringify(this.#list));
    }

    get length() {
        return this.#list.length;
    }

    add(key, value = null) {
        if (!this.contains(key, value)) {
            this.#list.push([key, value]);
        }
    }

    clear() {
        this.#list = [];
    }

    contains(key, value) {
        return this.#list.find( item => item[0] == key && item[1] == value ) !== undefined;
    }

    compare() {
        if (this.length >= 2) {
            window.location = this.url();
        }
    }

    url() {
        const item_is_clean = function(text) {
            return text === null || text.match(/^[a-zA-Z0-9:_]+$/) !== null;
        };

        const is_clean = this.#list.every( item => item_is_clean(item[0]) &&
                                                   item_is_clean(item[1]) );

        if (is_clean) {
            const kv = this.#list.map( item => item[0] + (item[1] === null ? '' : ('=' + item[1])) );
            return '/compare/' + kv.join('/');
        }

        let params = new URLSearchParams();
        this.#list.forEach( item => params.append('key[]', item[0] ) );
        this.#list.forEach( item => params.append('value[]', item[1] || '' ) );

        return '/compare/?' + params.toString();
    }
}

class ComparisonListDisplay {

    #comparison_list;
    #key = null;
    #value = null;

    constructor(key, value = null) {
        const list = new ComparisonList();
        this.#comparison_list = list;
        this.#key = key;
        this.#value = value;

        list.load();
        this.update();

        document.getElementById('comparison-list-add').addEventListener('click', () => { list.add(key, value); list.store(); this.update(); });
        document.getElementById('comparison-list-clear').addEventListener('click', () => { list.clear(); list.store(); this.update(); });
        document.getElementById('comparison-list-compare').addEventListener('click', () => { list.compare(); });
    }

    update() {
        const length = this.#comparison_list.length;

        const title = document.querySelector('#comparison-list div');
        title.textContent = title.textContent.replace(/([0-9]+)/, String(length));

        const enable_disable = function(id, condition) {
            document.getElementById('comparison-list-' + id).className = condition ? '' : 'disabled';
        };

        enable_disable('add', !this.#comparison_list.contains(this.#key, this.#value));
        enable_disable('clear', length > 0);
        enable_disable('compare', length >= 2);
    }
}

/* ============================ */

function activate_josm_button() {
    if (jQuery('#josm_button').length != 0) {
        jQuery('#josm_button').bind('click', function() {
            const url = jQuery('#josm_button')[0].href;
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
    let out = '';
    if (icon) {
        out += img({src: icon, alt: '', style: 'max-width: 16px; max-height: 16px;'}) + ' ';
    }
    if (description) {
        out += html_escape(description) + ' ';
    }
    if (url) {
        out += '[' + link(url, 'More...', { target: '_blank', 'class': 'extlink' }) + ']';
    }
    return out;
}

/* ============================ */

jQuery(document).ready(function() {
    jQuery('#javascriptmsg').remove();

    jQuery('#help_link').bind('click', open_help);

    jQuery.getQueryString = (function(a) {
        if (a == "") return {};
        let b = {};
        for (var i = 0; i < a.length; i++) {
            const p = a[i].split('=');
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
            const query = ui.item.value;
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
                        return false;
                    case 99: // c
                        window.location = (new ComparisonList()).url();
                        return false;
                    case 102: // f
                        jQuery('input.qsbox').focus();
                        return false;
                    case 104: // h
                        window.location = '/';
                        return false;
                    case 107: // k
                        window.location = '/keys';
                        return false;
                    case 112: // p
                        window.location = '/projects';
                        return false;
                    case 114: // r
                        window.location = '/relations';
                        return false;
                    case 115: // s
                        jQuery('input#search').focus();
                        return false;
                    case 116: // t
                        window.location = '/tags';
                        return false;
                    case 120: // x
                        window.location = '/reports';
                        return false;
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
                    return false;
                case 33: // page up
                    jQuery('div.pPrev:visible').click();
                    return false;
                case 34: // page down
                    jQuery('div.pNext:visible').click();
                    return false;
                case 35: // end
                    jQuery('div.pLast:visible').click();
                    return false;
                case 37: // arrow left
                    up();
                    return false;
                case 38: // arrow up
                    table_up();
                    return false;
                case 39: // arrow right
                    table_right();
                    return false;
                case 40: // arrow down
                    table_down();
                    return false;
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

    jQuery('#tools').slicknav({
        prependTo: '#toolsmenu',
        label: ''
    });

    jQuery(window).resize(function() {
        jQuery('select').trigger('render');
        resize_box();
        resize_grid(current_grid);
    });
});

function tomorrow() {
    let d = new Date();
    d.setDate(d.getDate() + 1);
    return d.toISOString().substring(0, 10);
}

function draw_chronology_chart(data, filter) {
    const w = 900;
    const h = 400;
    const margin = { top: 10, right: 15, bottom: 60, left: 80 };

    if (data[0].date > '2007-10-07') {
        data.unshift({date: '2007-10-07', nodes: 0, ways: 0, relations: 0});
    }

    data.push({date: tomorrow(), nodes: 0, ways: 0, relations: 0});

    let sum = 0;
    data.forEach(function(d) {
        d.date = new Date(d.date);
        if (filter == 'all') {
            sum += d.nodes + d.ways + d.relations;
        } else {
            sum += d[filter];
        }
        d.sum = sum;
    });

    const t0 = data[0].date;
    const t1 = data[data.length - 1].date;

    const max = d3.max(data, d => d.sum);

    const scale_x = d3.scaleTime()
                      .domain([t0, t1])
                      .range([0, w]);

    const axis_x = d3.axisBottom(scale_x)
                     .tickFormat(d3.timeFormat('%b %Y'));

    const scale_y = d3.scaleLinear()
                      .domain([0, max])
                      .range([h, 0]);

    const line = d3.line().curve(d3.curveStepAfter)
                   .x(d => scale_x(d.date))
                   .y(d => scale_y(d.sum));

    d3.select('#chart-chronology svg').remove();

    const chart = d3.select('#chart-chronology').append('svg')
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
        .call(axis_x);

    chart.append('g')
        .attr('class', 'y axis')
        .attr('transform', 'translate(-5, 0)')
        .call(d3.axisLeft(scale_y));

    chart.append('path')
        .datum(data)
        .attr('fill', 'none')
        .attr('stroke', '#083e76')
        .attr('stroke-width', 1.5)
        .attr('stroke-linejoin', 'round')
        .attr('stroke-linecap', 'round')
        .attr('d', line);
}

/* ============================ */
