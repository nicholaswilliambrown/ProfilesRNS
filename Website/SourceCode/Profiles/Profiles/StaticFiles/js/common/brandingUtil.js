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
    await $.getJSON(`/Branding/myBranding.json`, function (data) {
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
function applySystematicBlurbs() {
    let topicClass = 'topic';
    let blurbClass = 'blurbForTopic';

    $(`.${topicClass}`).each((index, element) => {
        let elt = $(element);
        let sharedAttr = elt.attr('sharedAttr');
        let blurbAttrs = [];
        $(`.${blurbClass}[sharedAttr="${sharedAttr}"]`)
            .get() // to array
            .forEach(i => {
                blurbAttrs.push($(i).attr('blurb'));
            });

        hideEmptyTopics(sharedAttr, blurbAttrs);

        blurbAttrs.forEach(attr => {
            let elt = $(`div[blurb="${attr}"]`);
            let blurbText = gBrandingConstants[attr];
            $(elt).html(blurbText);
        });
    });
}
function hideEmptyTopics(sharedAttr, blurbAttrList) {
    let nonEmptyBlurbs = blurbAttrList.filter(ba =>
        gBrandingConstants[ba]);

    if ( ! nonEmptyBlurbs.length) {
        $(`div[sharedAttr="${sharedAttr}"]`).hide()
    }
}

