async function setupHelpAndAbout() {
    await commonSetup();

    moveContentByIdTo('aboutOrHelp', $('#mainDiv'));
    setupScrolling();

    $('.profilesTitleH').html(gBrandingConstants.profilesTitle);
}
