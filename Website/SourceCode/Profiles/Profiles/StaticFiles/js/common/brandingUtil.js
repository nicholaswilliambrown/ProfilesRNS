/////////////////////////////////////////////////////////////////////////
//   Customize to your brand by editing (to provide your own constants,
//        functions and css-properties, respectively) the following files:
//
//   - myBranding.json
//   - myBranding.js
//   - myBranding.css
//
/////////////////////////////////////////////////////////////////////////

let gBrandingConstants = {};

async function loadBrandingConstants() {
    await $.getJSON(gBasic.jsonBrandingConfig, function (data) {
        gBrandingConstants = data;
        setupGimpl(gBrandingConstants.profilesUrl);
    });
}
async function loadBrandingAssets() {
    await loadBrandingConstants();

    await setupHeadAndTabTitle();
    await emitBrandingHeader();
    await emitBrandingFooter();
}

