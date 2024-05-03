async function setupHelpAndAbout() {
    await commonSetup();

    moveContentByIdTo('aboutOrHelp', $('#mainDiv'));

    $('#griffinA').attr('href', gAbout.griffinUrl);
    $('#rnsA').attr('href', gAbout.rnsUrl);
    $('#licenseA').attr('href', gAbout.licenseUrl);

    $('.helpEmailA').attr('href', gBrandingConstants.helpEmail);
    $('.helpEmailH').html(gBrandingConstants.helpEmail.replace("mailto:",""));
    $('.profilesTitleH').html(gBrandingConstants.profilesTitle);

    setupScrolling();
}