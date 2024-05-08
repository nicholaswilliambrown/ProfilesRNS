
let gBrandingConstants = {};

// gBrandingConstants.staticFiles helps locate all the other site-specific resources
gBrandingConstants.staticRoot = "/StaticFiles/";

async function setupHeadAndTabTitle() {
    let title = $(document).attr('title');
    if (! title) {
        title = window.location.pathname;
    }
    $(document).attr('title', title + gBrandingConstants.tabTitleSuffix);
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
