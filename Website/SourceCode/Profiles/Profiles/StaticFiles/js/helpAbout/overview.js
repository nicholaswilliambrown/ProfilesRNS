async function setupOverview() {
    await setupHelpAndAbout();

    $('#griffinA').attr('href', gAbout.griffinUrl);
    $('#rnsA').attr('href', gAbout.rnsUrl);
    $('#licenseA').attr('href', gAbout.licenseUrl);
}
