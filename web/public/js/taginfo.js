// taginfo.js

var grids = {},
    current_grid = '',
    tabs = null,
    autocomplete = null,
    up = function() { window.location = build_link('/'); };

/* ============================ */

function init_tooltips() {
    const tooltips = document.querySelectorAll('*[data-tooltip-position]');
    const tt = document.getElementById('tooltip');

    for (const tooltip of tooltips) {
        if (tooltip.hasAttribute('title')) {
            tooltip.setAttribute('data-tooltip-text', tooltip.getAttribute('title'));
            tooltip.removeAttribute('title');
        }

        tooltip.addEventListener("mouseenter", function(ev) {
            ev.preventDefault();

            const b = this.getBoundingClientRect();

            let x, y;
            if (this.getAttribute('data-tooltip-position') == 'OnLeft') {
                x = b.x + window.scrollX;
                y = b.y + window.scrollY + b.height / 2;
            } else if (this.getAttribute('data-tooltip-position') == 'OnRight') {
                x = b.x + window.scrollX + b.width;
                y = b.y + window.scrollY + b.height / 2;
            } else {
                x = b.x + window.scrollX + b.width / 2;
                y = b.y + window.scrollY + b.height / 2;
            }

            tt.innerHTML = "<div class='tooltips'><div class='" + this.getAttribute("data-tooltip-position") + "'>" + this.getAttribute("data-tooltip-text") + "</div></div>";
            tt.style.display = 'inline-block';
            tt.style.left = '' + x + 'px';
            tt.style.top = '' + y + 'px';
        });

        tooltip.addEventListener("mouseleave", function(ev) {
            ev.preventDefault();
            tt.removeAttribute('style');
            tt.innerHTML = '';
        });
    }
}

function redraw_on_resize(chart) {
    let resizeTimer;
    window.addEventListener('resize', function() {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(() => chart.draw(), 250);
    });
}

/* ============================ */

function build_link_with_prefix(prefix, path, params) {
    if (params && Object.keys(params).length > 0) {
        const p = new URLSearchParams(params);
        path += '?' + p.toString();
    }
    return prefix + path;
}

const bad_chars_for_url = /[.=\/]/;

function url_for_key(key) {
    const k = encodeURIComponent(key);
    if (key.match(bad_chars_for_url)) {
        return build_link('/keys/?key=' + k);
    } else {
        return build_link('/keys/' + k);
    }
}

function url_for_tag(key, value) {
    const k = encodeURIComponent(key);
    const v = encodeURIComponent(value);
    if (key.match(bad_chars_for_url) || value.match(bad_chars_for_url)) {
        return build_link('/tags/?key=' + k + '&value=' + v);
    } else {
        return build_link('/tags/' + k + '=' + v);
    }
}

function url_for_rtype(rtype) {
    const t = encodeURIComponent(rtype);
    if (rtype.match(bad_chars_for_url)) {
        return build_link('/relations/?rtype=' + t);
    } else {
        return build_link('/relations/' + t);
    }
}

function url_for_project(id) {
    return build_link('/projects/' + encodeURIComponent(id));
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

    for (let i = 0; i < str.length; i++) {
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
    icon_url = build_link('/api/4/project/icon', { project: id });
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
    }

    return tag('div', hover_expand(link_to_wiki(image.title)), {
        'data-tooltip-position': 'OnTop',
        title: html_escape(img({ src: url }))
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
        return link_to_value(key, item.value, { 'data-tooltip-position': 'OnLeft', title: fmt_as_percent(item.fraction) });
    }).join(' &bull; ');
}

/* ============================ */

class ResizeManager {
    timer;
    callbacks = {};

    constructor() {
        window.addEventListener('resize', event => {
            clearTimeout(this.timer);
            this.timer = setTimeout(event => this.callCallbacks(), 250);
        });
    }

    addCallback(id, func) {
        this.callbacks[id] = func;
    }

    callCallbacks() {
        for (const id in this.callbacks) {
            const element = document.getElementById(id);
            if (element.parentNode.style.display == 'none') {
                if (grids[id]) {
                    grids[id].remove();
                    delete grids[id];
                }
                delete this.callbacks[id];
            } else {
                this.callbacks[id]();
            }
        }
    }
}

let resizeManager = new ResizeManager;

class DynamicTableColumn {

    name; // Name of this column
    display; // HTML that will be shown in this column
    width; // Width in pixels
    sortable = false; // Can we sort the table by this column?
    align = 'left'; // Header and content alignment
    title; // Optional tooltip title
    headerElement; // The DOM element for the header cell

    constructor(config) {
        this.name = config.name;
        this.display = config.display;
        this.width = config.width;

        if (config.sortable) {
            this.sortable = config.sortable;
        }

        if (config.align) {
            this.align = config.align;
        }

        if (config.title) {
            this.title = config.title;
        }
    }

    makeHeaderElement(num, max) {
        const element = document.createElement('div');
        element.classList.add('dt-header');
        element.dataset.name = this.name;

        element.style.gridColumnStart = num * 2 - 1;
        element.style.textAlign = this.align;

        if (this.sortable) {
            element.style.cursor = 'pointer';
        }

        if (this.title) {
            element.setAttribute('title', this.title);
            element.setAttribute('data-tooltip-position', 'OnTop');
        }

        if (num < max) {
            element.style.width = this.width + 'px';
        } else {
            element.style.minWidth = this.width + 'px';
        }

        element.innerHTML = this.display;

        this.headerElement = element;
        return element;
    }

    makeBodyElement(num, row, max) {
        const element = document.createElement('div');
        element.classList.add('dt-body');
        element.classList.add('dt-line' + (row % 2));
        element.classList.add('dt-col' + num);
        element.classList.add('dt-row' + row);

        element.style.textAlign = this.align;

        if (num + 1 < max) {
            element.style.width = this.width + 'px';
        }

        return element;
    }

    setWidth(width) {
        this.width = width;
        this.headerElement.style.width = width + 'px';
    }
}

class DynamicTable {

    element; // The div element for the whole table including the toolbar
    config; // The original table configuration
    toolbar; // The toolbar element
    table; // The div element used for the table
    queryInput; // The input element with the query
    columns = []; // The table column definitions

    usepager = true;
    page = 1; // The page currently displayed
    rp = 0; // The number of rows per page
    total = 0; // The total number of rows in this table

    currentRow = 0;

    constructor(element, config) {
        this.element = element;
        this.config = config;

        for (const column of this.config.colModel) {
            this.columns.push(new DynamicTableColumn(column));
        }

        if (this.config.usepager !== undefined && !this.config.usepager) {
            this.usepager = false;
        }
    }

    calculateRowsPerPage() {
        const rowHeight = 20 /*cell*/ + 2 * 2 /*cell padding*/;
        const parentHeight = this.element.parentNode.getBoundingClientRect().height;
        const parentPaddingHeight = 2 * 20;

        let height = parentHeight - parentPaddingHeight;
        for (const child of this.element.parentNode.children) {
            height -= child.getBoundingClientRect().height;
        }

        return Math.max(10, Math.floor(height / rowHeight) - 2);
    }

    hasSearch() {
        return this.config.searchitems !== undefined;
    }

    searchFor() {
        const s = this.config.searchitems;
        return s ? s[0].display : undefined;
    }

    initToolbar() {
        let tools = [];
        for (const toolClasses of ['dt-first dt-button', 'dt-prev dt-button', 'dt-page', 'dt-next dt-button', 'dt-last dt-button', 'dt-reload dt-button', 'dt-json no-print', 'dt-info', 'dt-search']) {
            const newElement = document.createElement('div');
            newElement.className = toolClasses;
            tools.push(newElement);
        }

        tools[0].addEventListener('click', this.goToFirstPage.bind(this));
        tools[1].addEventListener('click', this.goToPrevPage.bind(this));

        tools[2].innerHTML = '<span class="dt-page-msg">'
            + texts.flexigrid.pagetext
            + ' </span><input type="text" size="4"> '
            + texts.flexigrid.outof
            + ' <span class="dt-page-max"></span>';

        tools[2].addEventListener('change', event => {
            event.preventDefault();
            this.page = parseInt(event.target.value);
            this.load();
        });

        tools[3].addEventListener('click', this.goToNextPage.bind(this));
        tools[4].addEventListener('click', this.goToLastPage.bind(this));
        tools[5].addEventListener('click', this.load.bind(this));

        tools[6].innerHTML = '<a href="" target="_blank">JSON</a>';

        if (this.hasSearch()) {
            this.queryInput = document.createElement('input');
            this.queryInput.className = 'qsbox';
            this.queryInput.setAttribute('type', 'text');
            this.queryInput.setAttribute('size', 20);
            this.queryInput.setAttribute('name', 'q');
            this.queryInput.setAttribute('placeholder', texts.misc.search_for + ': ' + this.searchFor());
            this.queryInput.addEventListener('change', this.load.bind(this));

            this.queryInput.addEventListener('keydown', function(ev) {
                if (ev.key == 'Escape') {
                    ev.preventDefault();
                    this.blur();
                    return;
                }
                if (ev.key == 'Tab') {
                    ev.preventDefault();
                    document.getElementById('search').focus();
                }
            });

            tools[8].append(this.queryInput);
        }

        this.toolbar = document.createElement('div');
        this.toolbar.classList.add('dt-toolbar');
        this.toolbar.append(...tools);
        this.element.append(this.toolbar);
    }

    dragStart(el, num, event) {
        event.target.setPointerCapture(event.pointerId);
        event.preventDefault();

        const origWidth = this.columns[num - 1].width;
        const x = event.clientX;
        let dx = 0;

        el.onpointermove = (event) => {
            dx = event.clientX - x;
            const width = origWidth + dx;
            if (width >= 10 && width <= 1000) {
                this.columns[num - 1].setWidth(width);
                for (const c of this.element.querySelectorAll('.dt-col' + (num - 1))) {
                    c.style.width = width + 'px';
                }
            }
        };

        el.onpointerup = function(event) {
            el.onpointermove = null;
            el.onpointerup = null;
        };
    }

    clear() {
        for (const bodyElement of this.table.querySelectorAll('.dt-body,.dt-handle')) {
            bodyElement.remove();
        }
    }

    initHandles(num_rows) {
        const rowEnd = 'span ' + (num_rows + 1);
        for (let i = 1; i < this.columns.length; i++) {
            const handle = document.createElement('div');
            const element = document.createElement('div');
            element.classList.add('dt-handle');
            element.append(handle);
            element.style.gridColumnStart = i * 2;
            element.style.gridRowEnd = rowEnd;
            handle.addEventListener('dragstart', () => false);

            handle.addEventListener('pointerdown', this.dragStart.bind(this, element, i));

            this.table.append(element);
        }
    }

    initTable() {
        this.table = document.createElement('div');
        this.table.classList.add('dt-table');
        this.table.style.gridTemplateColumns = 'repeat(' + ((this.columns.length - 1) * 2) + ', min-content) auto';

        let n = 1;
        for (const column of this.columns) {
            const element = column.makeHeaderElement(n, this.columns.length);
            if (column.name == this.config.sortname) {
                element.classList.add('dt-sort-' + this.config.sortorder);
            }
            if (column.sortable) {
                element.addEventListener('click', event => this.sort(event));
            }
            this.table.append(element);
            n++;
        }

        if (this.usepager) {
            this.table.addEventListener('wheel', event => {
                if (!event.shiftKey) {
                    return;
                }
                if (event.deltaY < 0) {
                    event.preventDefault();
                    this.goToPrevPage();
                } else if (event.deltaY > 0) {
                    event.preventDefault();
                    this.goToNextPage();
                }
            });
        }

        this.table.addEventListener('click', event => {
            const rowClass = Array.prototype.find.call(event.target.classList, val => val.match(/^dt-row/));
            if (rowClass) {
                this.currentRow = parseInt(rowClass.substring(6)) + 1;
                this.updateCurrentRow();
            }
        });

        this.element.append(this.table);
    }

    sort(event) {
        const element = event.currentTarget;
        const columnName = element.dataset.name;
        if (this.config.sortname == columnName) {
            if (this.config.sortorder == 'asc') {
                this.config.sortorder = 'desc';
                element.classList.remove('dt-sort-asc');
            } else {
                this.config.sortorder = 'asc';
                element.classList.remove('dt-sort-desc');
            }
            element.classList.add('dt-sort-' + this.config.sortorder);
        } else {
            const sort_elements = element.parentNode.querySelectorAll('.dt-sort-asc,.dt-sort-desc');
            for (const el of sort_elements) {
                el.classList.remove('dt-sort-desc');
                el.classList.remove('dt-sort-asc');
            }
            element.classList.add('dt-sort-' + this.config.sortorder);
            this.config.sortname = columnName;
        }
        this.load();
    }

    setUpHTML() {
        if (this.usepager) {
            this.initToolbar();
            this.rp = this.calculateRowsPerPage();
        }
        this.initTable();

        this.element.classList.add('dynamic-table');
    }

    remove() {
        this.element.innerHTML = '';
    }

    firstRow() {
        return (this.page - 1) * this.rp + 1;
    }

    lastRow() {
        return Math.min(this.page * this.rp, this.total);
    }

    updateCurrentRow() {
        for (const element of this.table.querySelectorAll('.dt-current-row')) {
            element.classList.remove('dt-current-row');
        }

        if (this.currentRow == 0) {
            return;
        }

        for (const element of this.table.querySelectorAll('.dt-row' + (this.currentRow - 1))) {
            element.classList.add('dt-current-row');
        }
    }

    gotoPrevRow() {
        if (this.currentRow == 1) {
            if (this.page == 1) {
                return;
            }
            this.currentRow = this.rp;
            this.goToPrevPage();
        } else {
            this.currentRow--;
        }
        this.updateCurrentRow();
    }

    gotoNextRow() {
        if (this.rp == 0) {
            if (this.currentRow < this.total) {
                this.currentRow++;
            }
            this.updateCurrentRow();
            return;
        }

        if (this.page == this.max_page) {
            const cells = this.table.querySelectorAll('.dt-body');
            const last = Array.prototype.slice.call(cells, -1)[0];
            const lastRow = parseInt(Array.prototype.find.call(last.classList, val => val.match(/^dt-row/)).substring(6)) + 1;
            if (this.currentRow == lastRow) {
                return;
            }
        }
        if (this.currentRow == this.rp) {
            this.currentRow = 1;
            this.goToNextPage();
        } else {
            this.currentRow++;
        }
        this.updateCurrentRow();
    }

    get max_page() {
        return Math.ceil(this.total / this.rp);
    }

    goToFirstPage() {
        if (this.page == 1) {
            return;
        }
        this.page = 1;
        this.load();
    }

    goToPrevPage() {
        if (this.page == 1) {
            return;
        }
        this.page -= 1;
        this.load();
    }

    goToNextPage() {
        if (this.page == this.max_page) {
            return;
        }
        this.page += 1;
        this.load();
    }

    goToLastPage() {
        if (this.page == this.max_page) {
            return;
        }
        this.page = this.max_page;
        this.load();
    }

    makeActive(element) {
        while (!element.classList.contains('dt-col0')) {
            element = element.previousSibling;
        }
        for (let i = 0; i < this.columns.length; i++) {
            element.classList.add('active');
            element = element.nextSibling;
        }
    }

    makeInactive(element) {
        while (!element.classList.contains('dt-col0')) {
            element = element.previousSibling;
        }
        for (let i = 0; i < this.columns.length; i++) {
            element.classList.remove('active');
            element = element.nextSibling;
        }
    }

    fromToMessage(total) {
        let msg = '<span class="dt-wide">' + texts.flexigrid.pagestat;
        msg = msg.replace('{from}', '</span>' + this.firstRow() + '<span class="dt-narrow">\u2009\u2013\u2009</span><span class="dt-wide">');
        msg = msg.replace('{to}', '</span>' + this.lastRow() + '<span class="dt-narrow">\u2009/\u2009</span><span class="dt-wide">');
        msg = msg.replace('{total}', '</span>' + total + '<span class="dt-wide">');
        return msg + '</span>';
    }

    display(data) {
        this.total = data.total;

        if (this.toolbar) {
            this.toolbar.querySelector('.dt-page input').value = this.page;
            this.toolbar.querySelector('.dt-page span.dt-page-max').innerText = this.max_page;
            this.toolbar.querySelector('.dt-json a').setAttribute('href', data.url);

            this.toolbar.querySelector('.dt-info').innerHTML = this.fromToMessage(data.total);
        }

        this.clear();
        this.initHandles(data.rows.length);

        let elements = [];
        let row_num = 0;
        for (const row of data.rows) {
            let column = 0;
            for (const cell of row.cell) {
                const element = this.columns[column].makeBodyElement(column, row_num, this.columns.length);
                element.innerHTML = cell;
                element.addEventListener('mouseover', this.makeActive.bind(this, element));
                element.addEventListener('mouseout', this.makeInactive.bind(this, element));
                elements.push(element);
                column++;
            }
            row_num++;
        }

        this.table.append(...elements);

        init_tooltips();

        this.updateCurrentRow();

        if (this.usepager) {
            resizeManager.addCallback(this.element.id, this.resize.bind(this));
        }
    }

    resize() {
        if (this.controller) {
            this.controller.abort();
        }
        this.clear();
        this.rp = this.calculateRowsPerPage();
        this.load();
    }

    buildURL() {
        let p = {};

        for (const param in this.config.params) {
            p[param] = this.config.params[param];
        }

        if (this.config.sortname) {
            p.sortname = this.config.sortname;
            p.sortorder = this.config.sortorder;
        }

        if (this.usepager) {
            p.page = this.page;
            p.rp = this.rp;
        }

        if (this.queryInput !== undefined && this.queryInput.value != '') {
            p.query = this.queryInput.value;
        }

        return build_link(this.config.url, p);
    }

    load() {
        if (this.toolbar) {
            if (window.innerWidth <= 800) {
                this.toolbar.querySelector('.dt-info').innerText = '...';
            } else {
                this.toolbar.querySelector('.dt-info').innerText = texts.flexigrid.procmsg;
            }
        }

        if (this.controller) {
            this.controller.abort();
        }

        this.controller = new AbortController();
        fetch(this.buildURL(), { signal: this.controller.signal })
            .then( response => response.json() )
            .then( data => this.config.preProcess(data) )
            .then( data => { this.controller = undefined; this.display.apply(this, [data]); });
    }
}

function create_flexigrid(domid, options) {
    if (grids[domid]) {
        return;
    }

    const element = document.getElementById(domid);
    const dt = new DynamicTable(element, options);
    dt.setUpHTML();
    dt.load();
    grids[domid] = dt;
    current_grid = domid;
}

class Tabs {
    activateCallbacks = [];
    element;
    buttonBox;
    buttons;
    tabs;

    constructor(id) {
        this.element = document.getElementById(id);

        // First child is <ul> with tab buttons
        this.buttonBox = Array.from(this.element.children)[0];
        this.buttons = this.buttonBox.children;

        // Every child except the first is a tab
        this.tabs = Array.from(this.element.children).slice(1);

        this.buttonBox.dataset.left = ' ';
        this.buttonBox.dataset.right = ' ';

        for (const button of this.buttons) {
            button.addEventListener('click', this.click.bind(this));
        }
        for (const tab of this.tabs) {
            tab.classList.add('tabs-panel');
        }
    }

    choose(n) {
        for (const button of this.buttons) {
            button.classList.remove('active');
        }
        this.buttons[n].classList.add('active');
        for (const tab of this.tabs) {
            tab.style.display = 'none';
        }
        this.tabs[n].style.display = null;
        window.location.hash = this.tabs[n].id;

        if (n in this.activateCallbacks) {
            this.activateCallbacks[n]();
        }
    }

    get_index(tabname) {
        for (let n = 0; n < this.tabs.length; ++n) {
            if (this.tabs[n].id == tabname) {
                return n;
            }
        }
        return 0;
    }

    on_activate(tabname, func) {
        this.activateCallbacks[this.get_index(tabname)] = func;
    }

    activate(tabname) {
        this.choose(this.get_index(tabname));
    }

    click(ev) {
        if (ev.target) {
            ev.preventDefault();
            this.activate(ev.target.getAttribute('href').substring(1));
        }
    }
}

function init_tabs(params, callbacks) {
    tabs = new Tabs('tabs');

    if (params) {
        for (const tab in create_flexigrid_for) {
            tabs.on_activate(tab, create_flexigrid_for[tab].bind(this, ...params));
        }
    } else {
        for (const tab in create_flexigrid_for) {
            tabs.on_activate(tab, create_flexigrid_for[tab].bind(this));
        }
    }

    if (callbacks) {
        for (const tab in callbacks) {
            tabs.on_activate(tab, callbacks[tab]);
        }
    }

    if (window.location.hash == '') {
        tabs.choose(0);
    } else {
        tabs.activate(window.location.hash.substring(1));
    }

    return tabs;
}

function create_characters_flexigrid(string) {
    return create_flexigrid('grid-characters', {
        url: '/api/4/unicode/characters',
        params: { string: string },
        colModel: [
            { display: texts.unicode.character, name: 'character', width: 20, sortable: true },
            { display: texts.unicode.codepoint, name: 'codepoint', width: 60, sortable: true, align: 'right' },
            { display: texts.unicode.script, name: 'script', width: 100, sortable: true },
            { display: texts.unicode.general_category, name: 'general_category', width: 150, sortable: false },
            { display: texts.unicode.name, name: 'name', width: 150, sortable: false, align: 'left' }
        ],
        usepager: false,
        useRp: false,
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
    grids[current_grid].gotoPrevRow();
}

function table_down() {
    grids[current_grid].gotoNextRow();
}

function table_right() {
    const table = grids[current_grid];
    if (table.currentRow == 0) {
        return;
    }

    const apref = document.querySelectorAll('.dt-current-row a.pref');
    if (apref.length > 0) {
        window.location = apref[0].getAttribute('href');
        return;
    }

    const a = document.querySelectorAll('.dt-current-row a');
    if (a.length > 0) {
        window.location = a[0].getAttribute('href');
    }
}

/* ============================ */

class ComparisonList {

    list = [];

    constructor(list = []) {
        this.list = list.map(function(d) {
            if (d.value === undefined) {
                d.value = null;
            }
            return [d.key, d.value];
        });
    }

    load() {
        const tcl = window.sessionStorage.getItem('taginfo_comparison_list');
        this.list = tcl ? JSON.parse(tcl) : [];
    }

    store() {
        window.sessionStorage.setItem('taginfo_comparison_list', JSON.stringify(this.list));
    }

    get length() {
        return this.list.length;
    }

    add(key, value = null) {
        if (!this.contains(key, value)) {
            this.list.push([key, value]);
        }
    }

    clear() {
        this.list = [];
    }

    contains(key, value) {
        return this.list.find( item => item[0] == key && item[1] == value ) !== undefined;
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

        const is_clean = this.list.every( item => item_is_clean(item[0]) &&
                                                   item_is_clean(item[1]) );

        if (is_clean) {
            const kv = this.list.map( item => item[0] + (item[1] === null ? '' : ('=' + item[1])) );
            return '/compare/' + kv.join('/');
        }

        let params = new URLSearchParams();
        this.list.forEach( item => params.append('key[]', item[0] ) );
        this.list.forEach( item => params.append('value[]', item[1] || '' ) );

        return '/compare/?' + params.toString();
    }
}

class ComparisonListDisplay {

    comparison_list;
    key = null;
    value = null;

    constructor(key, value = null) {
        const list = new ComparisonList();
        this.comparison_list = list;
        this.key = key;
        this.value = value;

        list.load();
        this.update();

        document.getElementById('comparison-list-add').addEventListener('click', () => { list.add(key, value); list.store(); this.update(); });
        document.getElementById('comparison-list-clear').addEventListener('click', () => { list.clear(); list.store(); this.update(); });
        document.getElementById('comparison-list-compare').addEventListener('click', () => { list.compare(); });
    }

    update() {
        const length = this.comparison_list.length;

        const title = document.querySelector('#comparison-list div');
        title.textContent = title.textContent.replace(/([0-9]+)/, String(length));

        const enable_disable = function(id, condition) {
            document.getElementById('comparison-list-' + id).className = condition ? '' : 'disabled';
        };

        enable_disable('add', !this.comparison_list.contains(this.key, this.value));
        enable_disable('clear', length > 0);
        enable_disable('compare', length >= 2);
    }
}

/* ============================ */

function activate_josm_button() {
    const button = document.getElementById('josm_button');
    if (!button) {
        return;
    }

    button.addEventListener('click', async function(ev) {
        ev.preventDefault();
        try {
            const response = await fetch(button.getAttribute('href'));
            const text = await response.text();

            if (!response.ok || text.substring(0, 2) != 'OK') {
                throw new Error(text);
            }
        } catch (error) {
            console.log("Error when contacting JOSM: ", error);
            alert("Problem contacting JOSM. Is it running? Is remote control activated?");
        }
    });
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

class Autocomplete {
    constructor(id, results) {
        this.data = [];
        this.current = 0;
        this.value = '';
        this.element = document.getElementById(id);
        this.results = document.getElementById(results);
        this.source = '/search/suggest?format=simple&term=';
        this.element.addEventListener('input', this.trigger.bind(this));
        this.element.parentNode.addEventListener('keydown', this.key.bind(this));
    }

    trigger(ev) {
        this.value = this.element.value;
        if (this.value.length < 2) {
            this.clear();
            return;
        }
        fetch(this.source + encodeURIComponent(this.value))
            .then( (response) => response.json() )
            .then( (data) => this.display.apply(this, [data]) );
    }

    update() {
        this.element.value = this.current == 0 ? this.value : this.data[this.current - 1];
        let n = 1;
        for (let c of this.results.children) {
            if (n == this.current) {
                c.classList.add('active');
            } else {
                c.classList.remove('active');
            }
            n += 1;
        }
    }

    key(ev) {
        if (event.key == 'ArrowUp') {
            ev.preventDefault();
            if (this.current == 0) {
                this.current = this.data.length;
            } else {
                this.current -= 1;
            }
            this.update();
        } else if (event.key == 'ArrowDown') {
            ev.preventDefault();
            if (this.current == this.data.length) {
                this.current = 0;
            } else {
                this.current += 1;
            }
            this.update();
        } else if (event.key == 'Enter') {
            if (this.current > 0) {
                ev.preventDefault();
                window.location = this.results.children[this.current - 1].href;
            }
        } else if (event.key == 'Escape') {
            ev.preventDefault();
            this.clear();
            this.element.value = this.value;
            this.element.focus();
        }
    }

    clear() {
        this.current = 0;
        this.data = [];
        this.results.innerHTML = '';
        this.results.style.display = null;
    }

    display(data) {
        if (data.length == 0) {
            this.clear();
            return;
        }
        this.current = 0;
        this.data = data;
        let out = '';
        for (let d of data) {
            const link = d.match(/=/) ? build_link('/tags/' + d) : build_link('/keys/' + d);
            out += '<a href="' + link + '">' + d + '</a>';
        }
        this.results.innerHTML = out;
        this.results.style.display = 'block';
    }
}

/* ============================ */

function whenReady() {
    document.getElementById('javascriptmsg').remove();

    if (typeof page_init === 'function') {
        page_init();
    }

    init_tooltips();

    // Initialize language switcher
    document.getElementById('locale').addEventListener('change', function() {
        document.getElementById('url').value = window.location.pathname;
        document.getElementById('set_language').submit();
    });

    autocomplete = new Autocomplete('search', 'suggestions');

    document.addEventListener('keypress', function(event) {
        if (event.ctrlKey || event.altKey || event.metaKey) {
            return;
        }

        if (event.target != document.body) {
            return;
        }

        if (event.which >= 49 && event.which <= 57) { // digit
            tabs.choose(event.which - 49);
            return;
        }

        switch (event.key) {
            case 'c':
                window.location = (new ComparisonList()).url();
                break;
            case 'f':
                event.preventDefault();
                for (element of document.querySelectorAll('input.qsbox')) {
                    element.focus();
                }
                break;
            case 'h':
                window.location = build_link('/');
                break;
            case 'k':
                window.location = build_link('/keys');
                break;
            case 'p':
                window.location = build_link('/projects');
                break;
            case 'r':
                window.location = build_link('/relations');
                break;
            case 's':
                event.preventDefault();
                document.getElementById('search').focus();
                break;
            case 't':
                window.location = build_link('/tags');
                break;
            case 'x':
                window.location = build_link('/reports');
                break;
        }
    });

    document.addEventListener('keyup', function(event) {
        if (event.ctrlKey || event.altKey || event.metaKey) {
            return;
        }

        if (event.target != document.body) {
            return;
        }

        switch (event.key) {
            case 'Home':
                event.preventDefault();
                grids[current_grid].goToFirstPage();
                break;
            case 'PageUp':
                event.preventDefault();
                grids[current_grid].goToPrevPage();
                break;
            case 'PageDown':
                event.preventDefault();
                grids[current_grid].goToNextPage();
                break;
            case 'End':
                event.preventDefault();
                grids[current_grid].goToLastPage();
                break;
            case 'ArrowLeft':
                event.preventDefault();
                up();
                break;
            case 'ArrowUp':
                event.preventDefault();
                table_up();
                break;
            case 'ArrowRight':
                event.preventDefault();
                table_right();
                break;
            case 'ArrowDown':
                event.preventDefault();
                table_down();
                break;
        }
    });

    document.addEventListener('keydown', function(event) {
        if (event.target == document.body && event.key == 'Tab') {
            event.preventDefault();
            document.getElementById('search').focus();
        }
    });

    document.getElementById('search').addEventListener('keyup', function(event) {
        if (event.key == 'Escape') {
            event.preventDefault();
            this.blur();
        }
    });

    document.getElementById('search').addEventListener('keydown', function(event) {
        if (event.key == 'Tab') {
            event.preventDefault();
            for (element of document.querySelectorAll('input.qsbox')) {
                element.focus();
            }
        }
    });

    document.getElementById('search_form').addEventListener('submit', function(event) {
        if (document.getElementById('search').value == '') {
            event.preventDefault();
        }
    });

    const menu_button = document.getElementById('menu-button');
    menu_button.addEventListener('click', function(ev) {
        const menu = document.getElementById('menu');
        if (menu.style.display) {
            menu.style.display = null;
            menu_button.classList.remove('active');
        } else {
            menu.style.display = 'block';
            menu_button.classList.add('active');
        }
    });

    const tools_button = document.getElementById('toolsmenu');
    if (tools_button) {
        tools_button.addEventListener('click', function(ev) {
            const tools = document.getElementById('tools');
            if (tools.style.display) {
                tools.style.display = null;
            } else {
                tools.style.display = 'block';
            }
        });
    }
}

function tomorrow() {
    let d = new Date();
    d.setDate(d.getDate() + 1);
    return d.toISOString().substring(0, 10);
}

function draw_chronology_chart(data, filter) {
    const box_width = document.getElementById('chart-chronology').getBoundingClientRect().width;
    const w = Math.min(900, box_width - 100);
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
                     .tickFormat(d3.timeFormat(w > 500 ? '%b %Y' : '%Y'));

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

    resizeManager.addCallback('chart-chronology', () => draw_chronology_chart(data, filter) );
}

/* ============================ */

if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", whenReady);
} else {
    whenReady();
}

