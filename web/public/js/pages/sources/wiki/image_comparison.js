function page_init() {
    document.querySelectorAll('.keyimg').forEach(function(element, index) {
        const key = new TaginfoKey(context.keys[index]);
        element.setAttribute('href', key.url());
        element.textContent = key.content().replaceAll(':', '\u200b:');
    });
}
