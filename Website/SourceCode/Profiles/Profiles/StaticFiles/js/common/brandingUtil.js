/////////////////////////////////////////////////////////////////////////
//   Customize to your brand by editing (to provide your own constants,
//        functions and css-properties, respectively) the following files:
//
//   - myBranding.json
//   - myBranding.js
//   - myBranding.css
//
/////////////////////////////////////////////////////////////////////////

async function loadBrandingConstants() {
    await $.getJSON(gCommon.urlForBrandingConstantsJson, function (data) {
        gCommon.brandingConstants = data;
        setupGimpl(gCommon.brandingConstants.profilesUrl);
    });
}
async function loadBrandingAssets() {
    await loadBrandingConstants();

    await emitBrandingHeadItems();
    await emitBrandingHeader();
    await emitBrandingFooter();
}

