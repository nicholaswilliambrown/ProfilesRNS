async function setupHelpAndAbout(doSystematicBlurbs, andThen) {
    await commonSetup();

    moveContentByIdTo('aboutOrHelp', $('#mainDiv'));
    setupScrolling();

    $('.profilesTitleH').html(gBrandingConstants.profilesTitle);

    if (doSystematicBlurbs) {
        applySystematicBlurbs();
    }
    if (andThen) {
        andThen();
    }
}

function applySystematicBlurbs() {
    let topicClass = 'topic';
    let blurbClass = 'blurbForTopic';

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

    $('#whatIsIt').html(gBrandingConstants["aboutProfiles-whatIsIt"]);
    $('.aboutProfiles-profilesTitle').html(gBrandingConstants["aboutProfiles-profilesTitle"]);
    $('.aboutProfiles-profilesInstitution').html(gBrandingConstants["aboutProfiles-profilesInstitution"]);

    $('#calloutLhs').addClass(gCommon.cols5or12);
    $('#calloutRhs').addClass(gCommon.cols5or12);
}