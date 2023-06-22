function page_init() {
    for (let d of context.data) {
        d.keyOrTag = createKeyOrTagFromHash(d);
    }

    activateTagHistoryButton(context.data);

    const fetch_promises = context.data.map(function(d, index) {
        let params = { key: d.key };
        if (d.keyOrTag.type == 'tag') {
            params['value'] = d.value;
        }
        const url = build_link('/api/4/' + d.keyOrTag.type + '/overview', params);

        return fetch(url).
            then( response => response.json() ).
            then( d => { fill_data(d.data, index); return d; } );
    });

    Promise.all(fetch_promises).then(r => data_complete(r.map(d => d.data)));
}

function get_el(index, el) {
    return document.querySelector('.item' + index + el);
}

function fill_data(item, index) {
    const cl = new ComparisonList();
    context.data.forEach(function(ditem, i) {
        if (i != index) {
            cl.add(ditem.keyOrTag);
        }
    });
    get_el(index, ' a.close').setAttribute('href', cl.url());

    const itemObject = createKeyOrTag(item.key, item.value);
    get_el(index, ' h2').innerHTML = itemObject.fullLink();

    const descElement = get_el(index, '.description');
    const lang = item.description[context.lang] ? context.lang : 'en';
    if (item.description[lang]) {
        descElement.setAttribute('lang', lang);
        descElement.setAttribute('dir', item.description[lang].dir);
        descElement.innerText = item.description[lang].text;
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
        imgNodes.setAttribute('src', build_link(apiPrefix + 'nodes', apiParams));
        imgNodes.setAttribute('alt', '');
        imgNodes.style.position = 'absolute';
        imgNodes.style.zIndex = '2';

        const imgWays = document.createElement('img');
        imgWays.className = 'map map-fg';
        imgWays.setAttribute('src', build_link(apiPrefix + 'ways', apiParams));
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
