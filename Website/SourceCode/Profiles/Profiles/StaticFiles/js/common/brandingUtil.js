/////////////////////////////////////////////////////////////////////////
//   Customize to your brand by editing the following files (to provide
//        your own constants, blurbs, js-functions and css-properties):
//
//   - myBranding.json
//   - myBranding.js
//   - myBranding.css
//
/////////////////////////////////////////////////////////////////////////

async function loadBrandingConstants() {
    await $.getJSON(`${gBrandingConstants.staticRoot}Configuration/myBranding.json`, function (data) {
        gBrandingConstants = {...gBrandingConstants, ...data};

        gBrandingConstants.jsBrandingImageFiles =   `${gBrandingConstants.staticRoot}img/branding/`;
        gBrandingConstants.jsCommonImageFiles =     `${gBrandingConstants.staticRoot}img/common/`;
        gBrandingConstants.jsPagingImageFiles =     `${gBrandingConstants.staticRoot}img/paging/`;
        gBrandingConstants.jsPersonImageFiles =     `${gBrandingConstants.staticRoot}img/person/`;
        gBrandingConstants.jsSearchImageFiles =     `${gBrandingConstants.staticRoot}img/search/`;
        gBrandingConstants.htmlFiles =              `${gBrandingConstants.staticRoot}html-templates/`;

        setupBrandingDependentVals();
    });
}
async function loadBrandingAssets(targetId) {
    await loadBrandingConstants();

    await setupHeadIncludesAndTabTitle();
    await emitBrandingHeader(targetId);
    await emitBrandingFooter(targetId);
}
function unHideFooter() {
    $('#brandingFooter').show();
}

