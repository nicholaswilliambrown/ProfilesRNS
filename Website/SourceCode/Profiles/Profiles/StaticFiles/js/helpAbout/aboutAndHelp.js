async function setupHelpAndAbout(doSystematicBlurbs, andThen, title) {
    await commonSetup(title);

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

function setupOverview() {
    $('#rnsA').attr('href', gAbout.rnsUrl);
    $('#licenseA').attr('href', gAbout.licenseUrl);

    $('#whatIsIt').html(gBrandingConstants["aboutProfiles-whatIsIt"]);
    $('.aboutProfiles-profilesTitle').html(gBrandingConstants["aboutProfiles-profilesTitle"]);
    $('.aboutProfiles-profilesInstitution').html(gBrandingConstants["aboutProfiles-profilesInstitution"]);

    $('#calloutLhs').addClass(gCommon.cols5or12);
    $('#calloutRhs').addClass(gCommon.cols5or12);
}
