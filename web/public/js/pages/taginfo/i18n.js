function page_init() {
    const id = document.getElementById('lang');
    id.addEventListener('change', () => id.parentNode.submit());
}
