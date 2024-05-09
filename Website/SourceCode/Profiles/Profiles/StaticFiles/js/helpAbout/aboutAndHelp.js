async function setupHelpAndAbout(prefix, andThen) {
    await commonSetup();

    moveContentByIdTo('aboutOrHelp', $('#mainDiv'));
    setupScrolling();

    $('.profilesTitleH').html(gBrandingConstants.profilesTitle);

    if (prefix) {
        applyBlurb(prefix);
    }
    if (andThen) {
        andThen();
    }
}

function applyBlurb(generalClassPrefix) {
    let topicClass = generalClassPrefix + 'Topic';
    let blurbClass = generalClassPrefix + 'Blurb';

    $(`.${topicClass}`).each((index, element) => {
        let elt = $(element);
        let sharedAttr = elt.attr('sharedAttr');
        let blurbAttrList = $(`.${blurbClass}[sharedAttr="${sharedAttr}"]`)
            .attr('blurb');
        // singles assimilated into array type
        if (typeof blurbAttrList == "string") {
            blurbAttrList = [ blurbAttrList ];
        }

        hideEmptyTopics(sharedAttr, blurbAttrList);

        $.each(blurbAttrList, (index, attr) => {
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
function setupOverview() {
    $('#griffinA').attr('href', gAbout.griffinUrl);
    $('#rnsA').attr('href', gAbout.rnsUrl);
    $('#licenseA').attr('href', gAbout.licenseUrl);
}