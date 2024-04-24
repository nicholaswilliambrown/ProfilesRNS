
async function emitBrandingHeadItems() {
    // no added content / logic
}
async function emitBrandingHeader() {

    let header = $(`<div id="brandingBanner" class="mb-3"></div>`);
    $('body').prepend(header);

    let bannerDiv = $('<div class="d-flex justify-content-center headerBanner w-100"></div>');
    header.append(bannerDiv);
}
async function emitBrandingFooter() {
    // no added content / logic
}
