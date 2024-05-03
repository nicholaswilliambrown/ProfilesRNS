async function setupHelpAndAbout() {
    await commonSetup();

    moveContentByIdTo('aboutOrHelp', $('#mainDiv'));

    $('#griffinA').attr('href', gAbout.griffinUrl);
    $('#rnsA').attr('href', gAbout.rnsUrl);
    $('#licenseA').attr('href', gAbout.licenseUrl);
    $('#mailContactA').attr('href', gBrandingConstants.helpEmail);

    setupScrolling();
}