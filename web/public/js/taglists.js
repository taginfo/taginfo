// Used for creating lists of tags from taginfo.
// See https://wiki.openstreetmap.org/wiki/Taginfo/Taglists
var taginfo_taglist = (function(){

    function html_escape(text) {
        return String(text).
                replace(/&/g, '&amp;').
                replace(/</g, '&lt;').
                replace(/>/g, '&gt;').
                replace(/"/g, '&quot;').
                replace(/'/g, '&#39;');
    }

    function link_to_noescape(url, text) {
        return '<a href="' + url + '">' + text + '</a>';
    }

    function link_to(url, text) {
        return link_to_noescape(url, html_escape(text));
    }

    function url_for_wiki(title) {
        var path = 'https://wiki.openstreetmap.org/wiki/';
        return path + encodeURIComponent(title);
    }

    function url_for_taginfo(path) {
        return 'https://taginfo.openstreetmap.org/' + path;
    }

    function taginfo_key_link(key) {
        return link_to(url_for_taginfo('keys/?') +
                       jQuery.param({ 'key': key }), key);
    }

    function taginfo_tag_link(key, value) {
        return link_to(url_for_taginfo('tags/?') +
                       jQuery.param({ 'key': key, 'value': value }), value);
    }

    function type_image(type) {
        return '<img src="' +
                 url_for_taginfo('img/types/' + type + '.16.png') +
                 '" width="16" height="16"/> ';
    }

    function wiki_prefix(lang, type) {
        if (lang === 'en') {
            return type + ':';
        }
        return lang + ':' + type + ':';
    }

    function wiki_key_link(lang, key) {
        return link_to(url_for_wiki(wiki_prefix(lang, 'Key') + key), key);
    }

    function wiki_tag_link(lang, key, value) {
        return link_to(url_for_wiki(wiki_prefix(lang, 'Tag') + key + '=' + value), value);
    }

    function column_name(lang, column) {
        var names = {
            'en': {
                'key': 'Key',
                'value': 'Value',
                'element': 'Element',
                'description': 'Description',
                'image': 'Image',
                'count': 'Count'
            },
            'de': {
                'key': 'Key',
                'value': 'Value',
                'element': 'Element',
                'description': 'Beschreibung',
                'image': 'Bild',
                'count': 'Anzahl'
            }
        };

        if (!names[lang]) {
            lang = 'en';
        }

        return names[lang][column];
    }

    var print_column = {
        'key': function(lang, data) {
            if (!data.wiki[lang]) {
                lang = 'en';
            }
            return wiki_key_link(lang, data.key);
        },
        'value': function(lang, data) {
            if (!data.wiki[lang]) {
                lang = 'en';
            }
            return wiki_tag_link(lang, data.key, data.value);
        },
        'element': function(lang, data) {
            var types = '';
            if (data.on_node)     { types += type_image('node');     }
            if (data.on_way)      { types += type_image('way');      }
            if (data.on_area)     { types += type_image('area');     }
            if (data.on_relation) { types += type_image('relation'); }
            return types;
        },
        'description': function(lang, data) {
            var d = data.wiki[lang] || data.wiki['en'];
            if (d && d.description) {
                return html_escape(d.description);
            }
            return "";
        },
        'image': function(lang, data) {
            var d = data.wiki[lang] || data.wiki['en'];
            if (d && d.image) {
                return link_to_noescape(url_for_wiki('wiki/' + d.image.image),
                                        '<img src="' + d.image.thumb_url_prefix + '100' + d.image.thumb_url_suffix + '"/>');
            }
            return "";
        },
        'count': function(lang, data) {
            return ['node', 'way', 'relation'].map(function(type) {
                return type_image(type) + data['count_' + type + 's'];
            }).join('<br/>');
        }
    };

    function td(content) { return '<td>' + content + '</td>'; }
    function th(content) { return '<th>' + content + '</th>'; }
    function tr(content) { return '<tr>' + content + '</tr>'; }

    function create_table(data, options) {
        var columns = ['key', 'value', 'element', 'description', 'image'];

        if (options.with_count) {
            columns.push('count');
        }

        return '<table class="taginfo-taglist"><thead><tr>' +
            columns.map(function(column) {
                return th(column_name(options.lang, column));
            }).join('') + '</tr></thead><tbody>' +
            data.map(function(d) {
                return tr(columns.map(function(column) {
                    return td(print_column[column](options.lang, d));
                }).join(''));
            }).join('') + '</tbody></table>';
    }

    function insert_table(element, tags, options) {
        var url = url_for_taginfo('/api/4/tags/list?');

        if (! options.lang) {
            options.lang = 'en';
        }

        if (tags.match(/=/)) {
            url += 'tags=' + encodeURIComponent(tags);
        } else {
            url += 'key=' + encodeURIComponent(tags);
        }

        jQuery.getJSON(url, function(json) {
            element.html(create_table(json.data, options));
        });
    }

    return {

        show_table: function(element, tags, options) {
            if (typeof(element) === 'string') {
                element = jQuery(element);
            }
            insert_table(element, tags, options);
        },

        convert_to_taglist: function(elements) {
            if (typeof(elements) === 'string') {
                elements = jQuery(elements);
            }
            elements.each(function() {
                var element = jQuery(this),
                    tags = element.data("taginfo-taglist-tags"),
                    options = element.data("taginfo-taglist-options");

                if (typeof(options) !== 'object') {
                    options = {};
                }

                insert_table(element, tags, options);
            });
        }

    };

})();

