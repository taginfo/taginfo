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
        const path = 'https://wiki.openstreetmap.org/wiki/';
        return path + encodeURIComponent(title);
    }

    function url_for_taginfo(path) {
        return 'https://taginfo.openstreetmap.org/' + path;
    }

    function type_image(type) {
        return '<img src="' +
                 url_for_taginfo('img/types/' + type + '.svg') +
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
        const names = {
            'cs': {
                'key': 'Klíč',
                'value': 'Hodnota',
                'element': 'Prvek',
                'description': 'Popis',
                'image': 'Ilustrace',
                'osmcarto_rendering': 'Ikona',
                'count': 'Počet'
            },
            'de': {
                'key': 'Key',
                'value': 'Value',
                'element': 'Element',
                'description': 'Beschreibung',
                'image': 'Bild',
                'osmcarto_rendering': 'Kartendarstellung',
                'count': 'Anzahl'
            },
            'en': {
                'key': 'Key',
                'value': 'Value',
                'element': 'Element',
                'description': 'Description',
                'image': 'Image',
                'osmcarto_rendering': 'Map rendering',
                'count': 'Count'
            },
            'eo': {
                'key': 'Ŝlosilo',
                'value': 'Valoro',
                'element': 'Objekto',
                'description': 'Priskribo',
                'image': 'Bildo',
                'osmcarto_rendering': 'Piktogramo',
                'count': 'Nombro'
            },
            'es': {
                'key': 'Clave',
                'value': 'Valor',
                'element': 'Tipo',
                'description': 'Descripción',
                'image': 'Imagen',
                'osmcarto_rendering': 'Ícono',
                'count': 'Recuento'
            },
            'fr': {
                'key': 'Clé',
                'value': 'Valeur',
                'element': 'Élément',
                'description': 'Description',
                'image': 'Image',
                'osmcarto_rendering': 'Icône',
                'count': 'Nombre'
            },
            'hu': {
                'key': 'Kulcs',
                'value': 'Érték',
                'element': 'Típus',
                'description': 'Leírás',
                'image': 'Kép',
                'osmcarto_rendering': 'Ikon',
                'count': 'Darab'
            },
            'it': {
                'key': 'Chiave',
                'value': 'Valore',
                'element': 'Tipo Oggetto',
                'description': 'Descrizione',
                'image': 'Immagine',
                'osmcarto_rendering': 'Icona',
                'count': 'Conteggio'
            },
            'ja': {
                'key': 'キー',
                'value': '値',
                'element': '種別',
                'description': '説明',
                'image': '画像',
                'osmcarto_rendering': 'アイコン',
                'count': '件数'
            },
            'ko': {
                'key': '키',
                'value': '값',
                'element': '요소',
                'description': '설명',
                'image': '사진',
                'osmcarto_rendering': '아이콘',
                'count': '사용 횟수'
            },
            'pl': {
                'key': 'Klucz',
                'value': 'Wartość',
                'element': 'Rodzaj',
                'description': 'Opis',
                'image': 'Obraz',
                'osmcarto_rendering': 'Ikona',
                'count': 'Liczba'
            },
            'pt': {
                'key': 'Chave',
                'value': 'Valor',
                'element': 'Tipo',
                'description': 'Descrição',
                'image': 'Imagem',
                'osmcarto_rendering': 'Ícone',
                'count': 'Contagem'
            },
            'ru': {
                'key': 'Ключ',
                'value': 'Значение',
                'element': 'Тип',
                'description': 'Описание',
                'image': 'Изображение',
                'osmcarto_rendering': 'Значок',
                'count': 'Количество'
            },
            'uk': {
                'key': 'Ключ',
                'value': 'Значення',
                'element': 'Тип',
                'description': 'Опис',
                'image': 'Зображення',
                'osmcarto_rendering': 'Значок',
                'count': 'Кількість'
            },
            'vi': {
                'key': 'Chìa khóa',
                'value': 'Giá trị',
                'element': 'Kiểu',
                'description': 'Miêu tả',
                'image': 'Hình ảnh',
                'osmcarto_rendering': 'Hình tượng',
                'count': 'Tổng số'
            },
            'zh-hans': {
                'key': '类别',
                'value': '值',
                'element': '元素',
                'description': '说明',
                'image': '照片',
                'osmcarto_rendering': '地图显示',
                'count': '计数'
            },
            'zh-hant': {
                'key': '鍵',
                'value': '值',
                'element': '元素',
                'description': '描述',
                'image': '照片',
                'osmcarto_rendering': '地圖標註',
                'count': '計數'
            }
        };

        if (!names[lang]) {
            lang = 'en';
        }

        return names[lang][column];
    }

    function get_lang(data, lang) {
        if (data.wiki && data.wiki[lang]) {
            return lang;
        }
        return 'en';
    }

    var print_column = {
        'key': function(lang, data) {
            return wiki_key_link(get_lang(data, lang), data.key);
        },
        'value': function(lang, data) {
            if (data.value === null) {
                return '';
            }
            return wiki_tag_link(get_lang(data, lang), data.key, data.value);
        },
        'element': function(lang, data) {
            let types = '';
            if (data.on_node)     { types += type_image('node');     }
            if (data.on_way)      { types += type_image('way');      }
            if (data.on_area)     { types += type_image('area');     }
            if (data.on_relation) { types += type_image('relation'); }
            return types;
        },
        'description': function(lang, data) {
            if (data.wiki) {
                const d = data.wiki[lang] || data.wiki['en'];
                if (d && d.description) {
                    return html_escape(d.description);
                }
            }
            return "";
        },
        'image': function(lang, data) {
            if (data.wiki) {
                const d = data.wiki[lang] || data.wiki['en'];
                if (d && d.image) {
                    return link_to_noescape(url_for_wiki(d.image.image),
                                            '<img src="' + d.image.thumb_url_prefix + '100' + d.image.thumb_url_suffix + '"/>');
                }
            }
            return "";
        },
        'osmcarto_rendering': function(lang, data) {
            if (data.wiki) {
                const d = data.wiki[lang] || data.wiki['en'];
                if (d && d.osmcarto_rendering) {
                    return link_to_noescape(url_for_wiki(d.osmcarto_rendering.image),
                                            '<img style="max-width: 120px; max-height: 120px;" src="' +
                                            d.osmcarto_rendering.thumb_url_prefix +
                                            (d.osmcarto_rendering.width - 1) +
                                            d.osmcarto_rendering.thumb_url_suffix +
                                            '" width="' +
                                            d.osmcarto_rendering.width +
                                            '" height="' +
                                            d.osmcarto_rendering.height +
                                            '"/>');
                }
            }
            return "";
        },
        'count': function(lang, data) {
            return ['node', 'way', 'relation'].map(function(type) {
                const value = data['count_' + type + 's'].toString().
                              replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1&#x202f;');
                return '<div style="text-align: right; white-space: nowrap;">' +
                       value + ' ' + type_image(type) + '</div>';
            }).join('');
        }
    };

    function td(content) { return '<td>' + content + '</td>'; }
    function th(content) { return '<th>' + content + '</th>'; }
    function tr(content) { return '<tr>' + content + '</tr>'; }

    function create_table(data, options) {
        let columns = ['key', 'value', 'element', 'description'];

        if (options.with_rendering) {
            columns.push('osmcarto_rendering');
        }

        columns.push('image');

        if (options.with_count) {
            columns.push('count');
        }

        return '<table class="wikitable taginfo-taglist"><thead><tr>' +
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
        let url = url_for_taginfo('api/4/tags/list?');

        if (! options.lang) {
            options.lang = 'en';
        }

        if (tags.match(/=/)) {
            url += 'tags=';
        } else {
            url += 'key=';
        }
        url += encodeURIComponent(tags);

        fetch(url).
            then(response => response.json()).
            then(function(json) {
                element.innerHTML = create_table(json.data, options);
                for (const img of element.querySelectorAll('td a img')) {
                    img.parentNode.parentNode.style.textAlign = 'center';
                }
        });
    }

    return {

        show_table: function(element, tags, options) {
            if (typeof(element) === 'string') {
                element = document.getElementById(element);
            }
            insert_table(element, tags, options);
        },

        convert_to_taglist: function(elements) {
            if (typeof(elements) === 'string') {
                elements = document.querySelectorAll(elements);
            }
            for (const element of elements) {
                const tags = element.dataset.taginfoTaglistTags;
                let options = JSON.parse(element.dataset.taginfoTaglistOptions);

                if (typeof(options) !== 'object') {
                    options = {};
                }

                insert_table(element, tags, options);
            }
        }

    };

})();

