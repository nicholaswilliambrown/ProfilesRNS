async function setupHelpAndAbout() {
    await commonSetup();

    moveContentByIdTo('aboutOrHelp', $('#mainDiv'));

    $('#griffinA').attr('href', gAbout.griffinUrl);

    setupScrolling();
}