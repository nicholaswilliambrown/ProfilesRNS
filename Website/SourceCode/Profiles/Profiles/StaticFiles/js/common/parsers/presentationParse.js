async function presentationsParser(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let url;

    try {
    url = gEditProp.getDataFunctionPrefix + sessionInfo.personNodeID + "&p=" + gEditProp.getSlideshareOntologyUrl;
    await getDataViaPost(url, function(data) {
        emitSlideshares(data, innerPayloadDiv)
    });

    }
    catch (oops) {
        console.log(`====Unable to $.get(), url: ${url}. Error: ${oops.message}`);
    }
}
