// taginfo.js

var tabs = null,
    autocomplete = null,
    up = function() { window.location = build_link('/'); };

/* ============================ */

class WidgetManager {
    timer;
    widgets = {};

    constructor() {
        window.addEventListener('resize', () => {
            clearTimeout(this.timer);
            this.timer = setTimeout(this.resize.bind(this), 250);
        });

        document.addEventListener('keyup', event => this.keyUp.call(this, event) );
    }

    addWidget(widget) {
        this.widgets[widget.id] = widget;
    }

    resize() {
        for (const id in this.widgets) {
            const widget = this.widgets[id];
            widget.resize.apply(widget);
        }
    }

    keyUp(event) {
        if (event.ctrlKey || event.altKey || event.metaKey) {
            return;
        }

        if (event.target != document.body) {
            return;
        }

        for (const id in this.widgets) {
            if (this.widgets[id].keyUp) {
                this.widgets[id].keyUp(event);
                return;
            }
        }
    }
} // class WidgetManager

let widgetManager = new WidgetManager();

/* ============================ */

function initTooltips() {
    const tooltips = document.querySelectorAll('*[data-tooltip-position]');
    const tt = document.getElementById('tooltip');

    for (const tooltip of tooltips) {
        if (tooltip.hasAttribute('title')) {
            tooltip.setAttribute('data-tooltip-text', tooltip.getAttribute('title'));
            tooltip.removeAttribute('title');
        }

        tooltip.addEventListener("mouseenter", function(event) {
            event.preventDefault();

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

        tooltip.addEventListener("mouseleave", function(event) {
            event.preventDefault();
            tt.removeAttribute('style');
            tt.innerHTML = '';
        });
    }
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

class DynamicTableColumn {

    name; // Name of this column
    display; // HTML that will be shown in this column header
    width; // Width in widthUnits
    widthUnit = 'px';
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

        if (config.widthUnit) {
            this.widthUnit = config.widthUnit;
        }
    }

    makeHeaderElement(col, max) {
        const element = document.createElement('div');
        element.classList.add('dt-header');
        element.dataset.name = this.name;
        element.dataset.col = col;

        element.style.gridColumnStart = col * 2 + 1;
        element.style.textAlign = this.align;

        if (this.sortable) {
            element.style.cursor = 'pointer';
        }

        if (this.title) {
            element.setAttribute('title', this.title);
            element.setAttribute('data-tooltip-position', 'OnTop');
        }

        if (col + 1 < max) {
            element.style.width = this.width + this.widthUnit;
        } else {
            element.style.minWidth = this.width + this.widthUnit;
        }

        element.innerHTML = this.display;

        this.headerElement = element;
        return element;
    }

    makeBodyElement(col, row, max) {
        const element = document.createElement('div');
        element.className = 'dt-body';
        element.dataset.col = col;
        element.dataset.row = row;

        element.style.textAlign = this.align;

        if (col + 1 < max) {
            element.style.width = this.width + this.widthUnit;
        }

        return element;
    }

    setWidth(width) {
        this.width = width;
        this.headerElement.style.width = width + this.widthUnits;
    }
} // class DynamicTableColumn

class DynamicTable {
    id; // The id of this table
    element; // The div element for the whole table including the toolbar
    config; // The original table configuration
    toolbar; // The toolbar element
    table; // The div element used for the table
    queryInput; // The input element with the query
    columns = []; // The table column definitions

    usePager = true;
    rp = 0; // The number of rows per page

    totalRows = 0; // The total number of rows in this table
    currentRow = 0; // The current row (range: 0 to totalRows - 1)

    get currentPage() {
        return this.page(this.currentRow);
    }

    get maxPage() {
        return Math.ceil(this.totalRows / this.rp);
    }

    get rowOnPage() {
        return this.currentRow % this.rp;
    }

    constructor(id, config) {
        this.id = id;
        this.element = document.getElementById(id);

        if (!this.element) {
            throw new Error('No HTML object found with id "' + id + '" for DynamicTable.');
        }

        this.config = config;

        for (const column of this.config.colModel) {
            this.columns.push(new DynamicTableColumn(column));
        }

        if (this.config.usePager !== undefined && !this.config.usePager) {
            this.usePager = false;
        }

        if (this.usePager) {
            this.initToolbar();
        }
        this.initTable();

        this.element.classList.add('dynamic-table');
    }

    page(rowNum) {
        if (this.rp == 0) {
            return 0;
        }
        return Math.floor(rowNum / this.rp);
    }

    calculateRowsPerPage() {
        const rowHeight = 20 /*cell*/ + 2 * 2 /*cell padding*/;
        const parentHeight = this.element.parentNode.getBoundingClientRect().height;
        const padding = 2 * 20 /* top/bottom padding */ + 1 /* bottom border */;

        let height = parentHeight - padding;
        for (const child of this.element.parentNode.children) {
            height -= child.getBoundingClientRect().height;
        }

        return Math.max(10, Math.floor(height / rowHeight));
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
        for (const toolClasses of ['dt-first dt-button', 'dt-prev dt-button',
                                   'dt-page',
                                   'dt-next dt-button', 'dt-last dt-button',
                                   'dt-reload dt-button', 'dt-json no-print',
                                   'dt-info', 'dt-search']) {
            const newElement = document.createElement('div');
            newElement.className = toolClasses;
            tools.push(newElement);
        }

        tools[0].addEventListener('click', this.goToFirstPage.bind(this));
        tools[1].addEventListener('click', this.goToPrevPage.bind(this));

        tools[2].innerHTML = '<span class="dt-page-msg">'
            + texts.dynamic_table.pagetext
            + ' </span><input type="text" size="4"> '
            + texts.dynamic_table.outof
            + ' <span class="dt-page-max"></span>';

        tools[2].addEventListener('change', event => {
            event.preventDefault();
            let newPage = parseInt(event.target.value);
            if (newPage < 1) {
                newPage = 1;
                event.target.value = newPage;
            } else if (newPage > this.maxPage) {
                newPage = this.maxPage;
                event.target.value = newPage;
            }
            this.updateDisplay((newPage - 1) * this.rp);
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
            this.queryInput.addEventListener('change', () => {
                this.currentRow = 0;
                this.load();
            });

            this.queryInput.addEventListener('keydown', function(event) {
                if (event.key == 'Escape') {
                    event.preventDefault();
                    this.blur();
                    return;
                }
                if (event.key == 'Tab') {
                    event.preventDefault();
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

    dragStart(element, num, event) {
        event.target.setPointerCapture(event.pointerId);
        event.preventDefault();

        const origWidth = this.columns[num - 1].width;
        const x = event.clientX;
        let dx = 0;

        element.onpointermove = (event) => {
            dx = event.clientX - x;
            const width = origWidth + dx;
            if (width >= 10 && width <= 1000) {
                this.columns[num - 1].setWidth(width);
                for (const c of this.element.querySelectorAll('div[data-col="' + (num - 1) + '"]')) {
                    c.style.width = width + 'px';
                }
            }
        };

        element.onpointerup = function(event) {
            element.onpointermove = null;
            element.onpointerup = null;
        };
    }

    clearTableBody() {
        for (const bodyElement of this.table.querySelectorAll('.dt-body,.dt-handle,.dt-noresult')) {
            bodyElement.remove();
        }
    }

    initHandles(numRows) {
        const rowEnd = 'span ' + (numRows + 1);
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

        for (let col = 0; col < this.columns.length; col++) {
            const column = this.columns[col];
            const element = column.makeHeaderElement(col, this.columns.length);
            if (column.name == this.config.sortname) {
                element.classList.add('dt-sort-' + this.config.sortorder);
            }
            if (column.sortable) {
                element.addEventListener('click', event => this.sort(event));
            }
            this.table.append(element);
        }

        if (this.usePager) {
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
            const item = event.target.closest('.dt-body');
            if (item) {
                this.currentRow = this.currentPage * this.rp + parseInt(item.dataset.row);
                this.updateCurrentRowDisplay();
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
            const sortElements = element.parentNode.querySelectorAll('.dt-sort-asc,.dt-sort-desc');
            for (const el of sortElements) {
                el.classList.remove('dt-sort-desc');
                el.classList.remove('dt-sort-asc');
            }
            element.classList.add('dt-sort-' + this.config.sortorder);
            this.config.sortname = columnName;
        }
        this.currentRow = 0;
        this.load();
    }

    fromToMessage() {
        const firstRow = this.currentRow - this.rowOnPage + 1;
        const lastRow = Math.min(this.totalRows, firstRow + this.rp - 1);
        let msg = '<span class="dt-wide">' + texts.dynamic_table.pagestat;
        msg = msg.replace('{from}', '</span>' + firstRow + '<span class="dt-narrow">\u2009\u2013\u2009</span><span class="dt-wide">');
        msg = msg.replace('{to}', '</span>' + lastRow + '<span class="dt-narrow">\u2009/\u2009</span><span class="dt-wide">');
        msg = msg.replace('{total}', '</span>' + this.totalRows + '<span class="dt-wide">');
        return msg + '</span>';
    }

    display(data) {
        if (data.total == 0) {
            this.totalRows = 1;
            this.toolbar.querySelector('.dt-page input').value = '0';
            this.toolbar.querySelector('.dt-page span.dt-page-max').innerText = '0';
            this.toolbar.querySelector('.dt-json a').setAttribute('href', data.url);
            this.toolbar.querySelector('.dt-info').innerHTML = texts.dynamic_table.nomsg;

            this.clearTableBody();

            const noResultMessage = document.createElement('span');
            noResultMessage.className = 'empty';
            if (this.queryInput && this.queryInput.value != '') {
                noResultMessage.innerText = texts.dynamic_table.filter_nothing_found;
            } else if (this.config.empty) {
                noResultMessage.innerText = this.config.empty;
            } else {
                noResultMessage.innerText = texts.dynamic_table.nomsg;
            }

            const noResultElement = document.createElement('div');
            noResultElement.className = 'dt-noresult';
            noResultElement.append(noResultMessage);
            this.table.append(noResultElement);

            return;
        }

        this.totalRows = data.total;

        if (this.toolbar) {
            this.toolbar.querySelector('.dt-page input').value = this.currentPage + 1;
            this.toolbar.querySelector('.dt-page span.dt-page-max').innerText = this.maxPage;
            this.toolbar.querySelector('.dt-json a').setAttribute('href', data.url);

            this.toolbar.querySelector('.dt-info').innerHTML = this.fromToMessage();
        }

        this.clearTableBody();
        this.initHandles(data.rows.length);

        let elements = [];
        let rowNum = 0;
        for (const row of data.rows) {
            let column = 0;
            for (const cell of row.cell) {
                const element = this.columns[column].makeBodyElement(column, rowNum, this.columns.length);
                element.innerHTML = cell;
                element.addEventListener('mouseover', this.makeActive.bind(this, element));
                element.addEventListener('mouseout', this.makeInactive.bind(this, element));
                elements.push(element);
                column++;
            }
            rowNum++;
        }

        this.table.append(...elements);

        initTooltips();

        this.updateCurrentRowDisplay();

        if (this.usePager) {
            widgetManager.addWidget(this);
        }
    }

    resize() {
        if (this.controller) {
            this.controller.abort();
        }
        this.clearTableBody();
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

        if (this.usePager) {
            if (this.element.querySelectorAll('.dt-body,.dt-noresult').length == 0) {
                this.rp = this.calculateRowsPerPage();
            }
            p.rp = this.rp;
            p.page = this.currentPage + 1;
        }

        if (this.queryInput !== undefined && this.queryInput.value != '') {
            p.query = this.queryInput.value;
        }

        return build_link(this.config.url, p);
    }

    async load() {
        if (this.controller) {
            this.controller.abort();
        }

        if (this.toolbar) {
            if (window.innerWidth <= 800) {
                this.toolbar.querySelector('.dt-info').innerText = '...';
            } else {
                this.toolbar.querySelector('.dt-info').innerText = texts.dynamic_table.procmsg;
            }
        }

        this.controller = new AbortController();

        try {
            const response = await fetch(this.buildURL(), { signal: this.controller.signal });
            if (!response.ok) {
                throw new Error("Network error");
            }
            const json = await response.json();
            this.controller = undefined
            const data = this.config.preProcess(json)
            this.display(data);
        } catch (error) {
            this.clearTableBody();
            this.toolbar.querySelector('.dt-info').innerHTML = '<span class="bad">' + texts.dynamic_table.errormsg + '</span>';
        }
    }

    elementsInRow(row) {
        return this.table.querySelectorAll('div[data-row="' + row + '"]');
    }

    makeActive(element) {
        for (const el of this.elementsInRow(element.dataset.row)) {
            el.classList.add('active');
        }
    }

    makeInactive(element) {
        for (const el of this.elementsInRow(element.dataset.row)) {
            el.classList.remove('active');
        }
    }

    updateCurrentRowDisplay() {
        for (const element of this.table.querySelectorAll('.dt-current-row')) {
            element.classList.remove('dt-current-row');
        }

        for (const element of this.elementsInRow(this.rowOnPage)) {
            element.classList.add('dt-current-row');
        }
    }

    updateDisplay(newRow) {
        if (newRow < 0) {
            newRow = 0;
        } else if (newRow >= this.totalRows) {
            newRow = this.totalRows - 1;
        }

        if (this.currentRow == newRow) {
            return;
        }

        if (this.currentPage == this.page(newRow)) {
            this.currentRow = newRow;

            for (const element of this.table.querySelectorAll('.active')) {
                element.classList.remove('active');
            }

            this.updateCurrentRowDisplay();
            return;
        }

        this.currentRow = newRow;
        this.load();
    }

    goToPrevRow() {
        this.updateDisplay(this.currentRow - 1);
    }

    goToNextRow() {
        this.updateDisplay(this.currentRow + 1);
    }

    goToFirstPage() {
        this.updateDisplay(0);
    }

    goToPrevPage() {
        this.updateDisplay(this.currentRow - this.rp);
    }

    goToNextPage() {
        this.updateDisplay(this.currentRow + this.rp);
    }

    goToLastPage() {
        this.updateDisplay(this.totalRows - 1);
    }

    selectRow() {
        const apref = this.element.querySelectorAll('.dt-current-row a.pref');
        if (apref.length > 0) {
            window.location = apref[0].getAttribute('href');
            return;
        }

        const a = this.element.querySelectorAll('.dt-current-row a');
        if (a.length > 0) {
            window.location = a[0].getAttribute('href');
        }
    }

    keyUp(event) {
        switch (event.key) {
            case 'Home': event.preventDefault(); this.goToFirstPage(); break;
            case 'PageUp': event.preventDefault(); this.goToPrevPage(); break;
            case 'PageDown': event.preventDefault(); this.goToNextPage(); break;
            case 'End': event.preventDefault(); this.goToLastPage(); break;
            case 'ArrowUp': event.preventDefault(); this.goToPrevRow(); break;
            case 'ArrowDown': event.preventDefault(); this.goToNextRow(); break;
            case 'ArrowRight': event.preventDefault(); this.selectRow(); break;
        }
    }
} // class DynamicTable

function createDynamicTable(id, options) {
    const dt = new DynamicTable(id, options);
    dt.load();
    return dt;
}

class Tabs {
    element;
    buttons;
    tabs;
    widgets = [];
    state = [];
    numTabs;
    currentTab;

    constructor(id) {
        this.element = document.getElementById(id);

        const children = Array.from(this.element.children);

        // First child is <ul> with tab buttons
        this.buttons = children[0].children;
        this.numTabs = this.buttons.length;

        // Every child except the first is a tab
        this.tabs = children.slice(1);

        for (const button of this.buttons) {
            button.addEventListener('click', this.click.bind(this));
        }

        for (let i = 0; i < this.numTabs; i++) {
            this.widgets[i] = [];
        }
    }

    setTabFromURL() {
        if (window.location.hash == '') {
            this.choose(0);
        } else {
            this.activate(window.location.hash.substring(1));
        }
    }

    choose(n) {
        this.currentTab = n;
        for (const button of this.buttons) {
            button.classList.remove('active');
        }
        this.buttons[n].classList.add('active');
        for (const tab of this.tabs) {
            tab.style.display = 'none';
        }
        this.tabs[n].style.display = 'block';
        window.location.hash = this.tabs[n].id;

        for (const widget of this.widgets[this.currentTab]) {
            if (this.state[this.currentTab] == 'resize') {
                if (widget && widget.resize) {
                    widget.resize();
                }
            } else if (this.state[this.currentTab] != 'ok') {
                if (widget && widget.load) {
                    widget.load();
                } else if (widget && widget.draw) {
                    widget.draw();
                }
            }
        }
        this.state[this.currentTab] = 'ok';
    }

    getIndex(tabname) {
        for (let n = 0; n < this.tabs.length; ++n) {
            if (this.tabs[n].id == tabname) {
                return n;
            }
        }
        return 0;
    }

    activate(tabname) {
        this.choose(this.getIndex(tabname));
    }

    click(event) {
        if (event.target) {
            event.preventDefault();
            const href = event.target.closest('[href]').getAttribute('href');
            if (href) {
                const scroll = window.scrollY;
                this.activate(href.substring(1));
                window.scrollTo({ top: scroll });
            }
        }
    }

    keyUp(event) {
        if (event.which >= 49 && event.which <= 57) { // digit
            this.choose(event.which - 49);
            return;
        }

        for (const widget of this.widgets[this.currentTab]) {
            if (widget && widget.keyUp) {
                widget.keyUp(event);
                return;
            }
        }
    }

    addWidget(tab, widget) {
        if (Array.isArray(widget)) {
            for (const w of widget) {
                this.widgets[this.getIndex(tab)].push(w);
            }
            return;
        }
        this.widgets[this.getIndex(tab)].push(widget);
    }

    resize() {
        for (const widget of this.widgets[this.currentTab]) {
            if (widget && widget.resize) {
                widget.resize();
            }
        }
        for (let i = 0; i < this.state.length; ++i) {
            if (i != this.currentTab) {
                this.state[i] = 'resize';
            }
        }
    }
} // class Tabs

function initTabs(config, params) {
    for (const tab in config) {
        try {
            tabs.addWidget(tab, config[tab].apply(this, params));
        } catch (e) {
            // Ignore tables that can't be created. This is usually because
            // there is no data available.
        }
    }
}

function createCharactersTable(string) {
    return new DynamicTable('grid-characters', {
        url: '/api/4/unicode/characters',
        params: { string: string },
        colModel: [
            { display: texts.unicode.character, name: 'character', width: 20 },
            { display: texts.unicode.codepoint, name: 'codepoint', width: 60, align: 'right' },
            { display: texts.unicode.script, name: 'script', width: 100 },
            { display: texts.unicode.general_category, name: 'general_category', width: 150 },
            { display: texts.unicode.name, name: 'name', width: 150, align: 'left' }
        ],
        usePager: false,
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
} // class ComparisonList

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
} // class ComparisonListDisplay

/* ============================ */

function activate_josm_button() {
    const button = document.getElementById('josm_button');
    if (!button) {
        return;
    }

    button.addEventListener('click', async function(event) {
        event.preventDefault();
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

    trigger(event) {
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

    key(event) {
        if (event.key == 'ArrowUp') {
            event.preventDefault();
            if (this.current == 0) {
                this.current = this.data.length;
            } else {
                this.current -= 1;
            }
            this.update();
        } else if (event.key == 'ArrowDown') {
            event.preventDefault();
            if (this.current == this.data.length) {
                this.current = 0;
            } else {
                this.current += 1;
            }
            this.update();
        } else if (event.key == 'Enter') {
            if (this.current > 0) {
                event.preventDefault();
                window.location = this.results.children[this.current - 1].href;
            }
        } else if (event.key == 'Escape') {
            event.preventDefault();
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
} // class Autocomplete

/* ============================ */

function whenReady() {
    document.getElementById('javascriptmsg').remove();

    if (document.getElementById('tabs')) {
        tabs = new Tabs('tabs');
    }

    if (typeof page_init === 'function') {
        page_init();
    }

    if (tabs) {
        widgetManager.addWidget(tabs);
        tabs.setTabFromURL();
    }

    initTooltips();

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

        if (event.key == 'ArrowLeft') {
            event.preventDefault();
            up();
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
    menu_button.addEventListener('click', () => {
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
        tools_button.addEventListener('click', () => {
            const tools = document.getElementById('tools');
            if (tools.style.display) {
                tools.style.display = null;
            } else {
                tools.style.display = 'block';
            }
        });
    }
}

class ChartChronology {
    id = 'chart-chronology';
    element;
    url;
    filter;
    data;

    constructor(url, filter) {
        this.element = document.getElementById(this.id);
        this.url = url;
        this.filter = filter;
    }

    async load() {
        const response = await fetch(this.url);
        const json = await response.json();
        this.data = this.prepareData(json.data);
        this.draw();
    }

    tomorrow() {
        let d = new Date();
        d.setDate(d.getDate() + 1);
        return d.toISOString().substring(0, 10);
    }

    prepareData(data) {
        if (data[0].date > '2007-10-07') {
            data.unshift({date: '2007-10-07', nodes: 0, ways: 0, relations: 0});
        }

        data.push({date: this.tomorrow(), nodes: 0, ways: 0, relations: 0});

        let sum = 0;
        data.forEach(d => {
            d.date = new Date(d.date);
            if (this.filter == 'all') {
                sum += d.nodes + d.ways + d.relations;
            } else {
                sum += d[this.filter];
            }
            d.sum = sum;
        });

        return data;
    }

    draw() {
        this.element.innerHTML = '';

        const boxWidth = this.element.getBoundingClientRect().width;
        const w = Math.min(900, boxWidth - 100);
        const h = 400;
        const margin = { top: 10, right: 15, bottom: 60, left: 80 };

        const t0 = this.data[0].date;
        const t1 = this.data[this.data.length - 1].date;

        const max = d3.max(this.data, d => d.sum);

        const scaleX = d3.scaleTime()
                         .domain([t0, t1])
                         .range([0, w]);

        const axisX = d3.axisBottom(scaleX)
                        .tickFormat(d3.timeFormat(w > 500 ? '%b %Y' : '%Y'));

        const scaleY = d3.scaleLinear()
                         .domain([0, max])
                         .range([h, 0]);

        const line = d3.line()
                       .curve(d3.curveStepAfter)
                       .x(d => scaleX(d.date))
                       .y(d => scaleY(d.sum));

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

        chart.append('path')
             .datum(this.data)
             .attr('fill', 'none')
             .attr('stroke', '#083e76')
             .attr('stroke-width', 1.5)
             .attr('stroke-linejoin', 'round')
             .attr('stroke-linecap', 'round')
             .attr('d', line);
    }

    resize() {
        this.draw();
    }
} // class ChartChronology

/* ============================ */

if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", whenReady);
} else {
    whenReady();
}

