
let gBrandingConstants = {};

// gBrandingConstants.staticFiles helps locate all the other site-specific resources
gBrandingConstants.staticRoot = g.staticRoot;

async function emitBrandingHeader(targetId) {

    let header = $(`<div id="brandingBanner" class="mb-3"></div>`);
    $(`#${targetId}`).prepend(header);

    let bannerDiv = $('<div class="d-flex justify-content-center headerBanner w-100"></div>');
    await header.append(bannerDiv);
}
async function emitBrandingFooter(targetId) {
    let brandingFooter = await $('#brandingBanner').clone();
    brandingFooter.attr('id', "brandingFooter");
    brandingFooter.hide(); // show once rest of page is loaded!
    await $(`#${targetId}`).append(brandingFooter);
}
async function setupHeadIncludesAndTabTitle() {
    setTabTitleAndOrFavicon();
}
