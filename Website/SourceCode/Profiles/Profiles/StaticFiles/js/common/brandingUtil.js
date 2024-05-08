/////////////////////////////////////////////////////////////////////////
//   Customize to your brand by editing (to provide your own constants, blurbs
//        functions and css-properties, respectively) the following files:
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
async function loadBrandingAssets() {
    await loadBrandingConstants();

    await setupHeadAndTabTitle();
    await emitBrandingHeader();
    await emitBrandingFooter();
}

