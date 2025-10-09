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
    await $.getJSON(`${gBrandingConstants.staticRoot}../Branding/myBranding.json`, function (data) {
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
async function loadBrandingAssets(targetId, title) {
    await loadBrandingConstants();

    await setupHeadIncludesAndTabTitle(title);
    await emitBrandingHeader(targetId);
    await emitBrandingFooter(targetId);
}
async function setupHeadIncludesAndTabTitle(title) {
    setTabTitleAndOrFavicon(title);
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
function continuallySizeFooter(footerId) {

    placeFooter(footerId);

    setInterval(function () {
        placeFooter(footerId);
    }, 200);
}

function placeFooter(footerId) {
    let footerPushDownId = 'footer-push-down';
    let footerPushDownDiv = $('#' + footerPushDownId);

    if (footerPushDownDiv.length == 0) {
        $(footerId).before('<div id="' + footerPushDownId + '"></div>');
    }

    let winHeight = $(window).height();
    let bodyHeight = $('body').height() - footerPushDownDiv.height();

    if (bodyHeight < winHeight) {
        footerPushDownDiv.height(winHeight - bodyHeight);
    }

    $(footerId).css("clear: both");
}

