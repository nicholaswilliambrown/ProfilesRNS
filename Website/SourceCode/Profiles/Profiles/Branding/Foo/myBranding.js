let gBrandingConstants = {};

// gBrandingConstants.staticFiles helps locate all the other site-specific resources
gBrandingConstants.staticRoot = "/StaticFiles/";

async function emitBrandingHeader() {

    $('body').prepend(`<div id="brandingBanner" class="d-flex justify-content-center headerFooter p-2"></div>`);

    let getHeaderContent = () => { return $(`<div>Foo University<br/>We lower the bar</div>`); }

    // versions for small and large
    let largeBannerDiv = $(`<div class="w-75 ${gCommon.hideXsSmallShowOthers}"></div>`);
    $('#brandingBanner').append(largeBannerDiv);
    largeBannerDiv.append(getHeaderContent());

    let smallBannerDiv = $(`<div class="w-75 ${gCommon.showXsSmallHideOthers}"></div>`);
    $('#brandingBanner').append(smallBannerDiv);
    smallBannerDiv.append(getHeaderContent());
}
async function emitBrandingFooter() {
    let brandingFooter = $(`<div id="brandingFooter" 
        class="d-flex justify-content-center headerFooter p-2"></div>`);
    $('body').append(brandingFooter);

    let getFooterContent = () => { return $(`<div class="small">Foo University<br/>Try not to trip on the bar</div>`); }

    // versions for small and large
    let largeFooterDiv = $(`<div class="w-75 ${gCommon.hideXsSmallShowOthers}"></div>`);
    brandingFooter.append(largeFooterDiv);
    largeFooterDiv.append(getFooterContent());

    let smallFooterDiv = $(`<div class="w-75 ${gCommon.showXsSmallHideOthers}"></div>`);
    brandingFooter.append(smallFooterDiv);
    smallFooterDiv.append(getFooterContent());
}
