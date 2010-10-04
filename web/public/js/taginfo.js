// taginfo.js

function print_wiki_link(title) {
    return '&rarr; <a class="wikilink" href="http://wiki.openstreetmap.org/wiki/' + title + '">' + title + '</a>';
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
    var v1 = value.print_with_ts();
    var v2 = fraction.print_as_percent();
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
Number.prototype.print_with_ts = function() {
    return this.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1&thinsp;');
};

// print a number as percent value with two digits after the decimal point
Number.prototype.print_as_percent = function() {
    return (this * 100).toFixed(2) + '%';
};

function pp_key(key) {
    if (key == '') {
        return '<b><i>empty string<i></b>';
    }
    return key.replace(/([&<>#;\/]+)/g, "<b>$1</b>").replace(/ /g, '<b>&#x2423;</b>').replace(/\s+/g, '<b>?</b>').replace(/([-!"\$%'()*+,.=?@\[\\\]^`{|}~]+)/g, "<b>$1</b>");
}

function pp_value(value) {
    if (value == '') {
        return '<b><i>empty string<i></b>';
    }
    return value.replace(/ /g, '&#x2423;').replace(/\s+/g, '<b>?</b>');
}

function link_to_key(key) {
    var k = encodeURIComponent(key);
    return '<a class="taglink" href="/keys/' + k +           '" title="' + k +           '">' + pp_key(key)     + '</a>';
}

function link_to_value(key, value) {
    var k = encodeURIComponent(key);
    var v = encodeURIComponent(value);
    return '<a class="taglink" href="/tags/' + k + '=' + v + '" title="' + k + '=' + v + '">' + pp_value(value) + '</a>';
}

function link_to_tag(key, value) {
    return link_to_key(key) + '=' + link_to_value(key, value);
}

String.prototype.to_key = function() {
    return link_to_key(this);
}

String.prototype.to_value = function(key) {
    return link_to_value(key, this);
};

