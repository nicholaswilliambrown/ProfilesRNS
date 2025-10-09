
let gBrandingConstants = {};

// gBrandingConstants.staticFiles helps locate all the other site-specific resources
gBrandingConstants.staticRoot = g.staticRoot;

async function emitBrandingHeader(targetId) {

    let header = $(`<div id="brandingBanner" class="mb-3"></div>`);
    $(`#${targetId}`).prepend(header);

    let bannerDiv = $('<div class="headerBanner w-100 d-flex justify-content-center"></div>');
    await header.append(bannerDiv);

    // potential for wide / narrow responsive alternates
    let imageDivWide = $('<div id="imageDivWide"></div>');
    bannerDiv.append(imageDivWide);
}
async function emitBrandingFooter(targetId) {
    let brandingFooter = $('<div id="brandingFooter"' +
        ' class="d-flex justify-content-center footerBanner w-100">' +
        'Profiles Research Networking Software was developed under the supervision of Griffin M Weber, MD, PhD, ' +
        'with support from Grant Number 1 UL1 TR002541 to Harvard Catalyst, ' +
        'The Harvard Clinical and Translational Science Center from the ' +
        'National Center for Advancing Translational Sciences and support from ' +
        'Harvard University and its affiliated academic healthcare centers.</div>');
    brandingFooter.hide(); // show once rest of page is loaded!
    await $(`#${targetId}`).append(brandingFooter);

    continuallySizeFooter('#brandingFooter');
}
async function setupHeadIncludesAndTabTitle() {
    setTabTitleAndOrFavicon();
}

