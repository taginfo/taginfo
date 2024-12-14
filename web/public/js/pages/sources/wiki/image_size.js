function page_init() {
    initTabs();

    for (const element of document.querySelectorAll('.imgbox p')) {
        const k = element.dataset.key;
        const v = element.dataset.value;
        const c = element.dataset.count;
        const keyOrTag = createKeyOrTag(k, v);

        var out = keyOrTag.link({ tab: 'wiki' });
        if (c == 1) {
            out += ' (1&nbsp;use)';
        } else if (c > 1) {
            out += ' (' + c + '&nbsp;uses)';
        }

        element.innerHTML = out;
    }
}
