function page_init() {
    for (let d of context.data) {
        d.keyOrTag = createKeyOrTagFromHash(d);
    }

    activateTagHistoryButton(context.data);

    const fetch_promises = context.data.map(function(dataItem, index) {
        let params = { key: dataItem.key };
        let key_or_tag = dataItem.keyOrTag;
        if (key_or_tag.type == 'tag') {
            params['value'] = dataItem.value;
        }
        const url = build_link_with_prefix(key_or_tag.instance, '/api/4/' + key_or_tag.type + '/overview', params);

        return fetch(url).
            then( response => response.json() ).
            then( d => { fill_data(key_or_tag.instance, d.data, index); return d; } );
    });

    Promise.all(fetch_promises).then(r => data_complete(r.map(d => d.data)));
}

function get_el(index, el) {
    return document.querySelector('.item' + index + el);
}

function fill_data(instance, item, index) {
    const cl = new ComparisonList();
    context.data.forEach(function(ditem, i) {
        if (i != index) {
            cl.add(ditem.keyOrTag);
        }
    });
    get_el(index, ' a.close').setAttribute('href', cl.url());

    const itemObject = createKeyOrTag(item.key, item.value);
    itemObject.instance = instance;
    get_el(index, ' h2').innerHTML = itemObject.fullLink();

    const descElement = get_el(index, '.description');
    const lang = item.description[context.lang] ? context.lang : 'en';
    if (item.description[lang]) {
        descElement.setAttribute('lang', lang);
        descElement.setAttribute('dir', item.description[lang].dir);
        descElement.innerText = item.description[lang].text;
    }
    if (instance != '') {
        const instanceElement = get_el(index, '.instance');
        instanceElement.innerText = context.instances[instance];
    }

    document.querySelectorAll('.item' + index + '.counts table td').forEach(function(c, index) {
        c.innerText = fmt_with_ts(item.counts[index].count);
    });

    if (!item.value && item.prevalent_values) {
        get_el(index, '.prevalent_values div b').textContent = h(texts.misc.prevalent_values) + ':';
        get_el(index, '.prevalent_values div.data').innerHTML = fmt_prevalent_value_list(itemObject.toKey(), item.prevalent_values);
    }

    get_el(index, '.wiki div b').innerText = texts.pages[itemObject.type].wiki_pages.title + ':';
    get_el(index, '.wiki div.data').innerHTML += item.wiki_pages.map(
        w => tag('span', html_escape(w.lang), {
            'class': 'badge lang',
            'data-tooltip-position': 'OnTop',
            title: html_escape(w.native + ' (' + w.english + ')')
        })
    ).join(' ');

    get_el(index, '.projects b').innerText = texts.pages[itemObject.type].projects.title + ':';
    get_el(index, '.projects .data').innerText = item.projects;
    itemObject.tab = 'projects';
    get_el(index, '.projects .data').setAttribute('href', itemObject.url());

    if (item.has_map) {
        const apiPrefix = '/api/4/' + (item.value ? 'tag' : 'key') + '/distribution/';
        let apiParams = { key: item.key };
        if (item.value) {
            apiParams.value = item.value;
        }

        const imgNodes = document.createElement('img');
        imgNodes.className = 'map map-fg';
        imgNodes.setAttribute('src', build_link_with_prefix(instance, apiPrefix + 'nodes', apiParams));
        imgNodes.setAttribute('alt', '');
        imgNodes.style.position = 'absolute';
        imgNodes.style.zIndex = '2';

        const imgWays = document.createElement('img');
        imgWays.className = 'map map-fg';
        imgWays.setAttribute('src', build_link_with_prefix(instance, apiPrefix + 'ways', apiParams));
        imgWays.setAttribute('alt', '');
        imgWays.style.zIndex = '3';

        const imgBg = document.createElement('img');
        imgBg.className = 'map map-bg';
        imgBg.setAttribute('src', context.backgroundImage);
        imgBg.setAttribute('alt', '');

        get_el(index, '.map div').append(imgNodes, imgWays, imgBg);
    }

    return item;
}

function data_complete(data) {
    const comparison_list = new ComparisonList(data);
    comparison_list.store();
    initTooltips();
}
