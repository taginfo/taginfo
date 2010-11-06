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

    return '<img src="/img/link-wiki.gif" alt=""/><a class="wikilink" href="http://wiki.openstreetmap.org/' + path + '" target="_blank">' + title + '</a>';
}

function print_language(code, lang) {
    return '<span class="lang" title="' + lang + '">' + code + '</span> ' + lang;
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
    return '<img src="/img/types/' + type + '.16.png" alt="[' + name + ']" title="' + name + '"/>';
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

function link_to_value(key, value) {
    var k = encodeURIComponent(key),
        v = encodeURIComponent(value),
        title = html_escape(key) + '=' + html_escape(value);

    if (key.match(/[=\/]/) || value.match(/[=\/]/)) {
        return '<a class="taglink" href="/tags/?key=' + k + '&value=' + v + '" title="' + title + '">' + pp_value(value) + '</a>';
    } else {
        return '<a class="taglink" href="/tags/' + k + '=' + v + '" title="' + title + '">' + pp_value(value) + '</a>';
    }
}

function link_to_tag(key, value) {
    return link_to_key(key) + '=' + link_to_value(key, value);
}

