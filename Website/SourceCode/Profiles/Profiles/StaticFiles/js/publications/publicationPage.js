async function setupPublicationPage() {
    let [json] = await commonSetupWithJson();
    // page json is also available in global: g.pageJSON

    let topData = getModuleData(json, 'Publication.GeneralInfo');
    let subjectsData = getModuleData(json, 'Publication.Concepts');
    let authorsData = getModuleData(json, 'Publication.Authors');

    let mainDiv = $('#mainDiv');

    emitTopItems(topData, mainDiv);
    emitSubjects(subjectsData, mainDiv);
    emitAuthors(authorsData, mainDiv);
}
function emitTopItems(data, mainDiv) {
    let title = data.Title;
    let citation = data.Citation;
    let url = data.URL;

    emitAndHistoricizeTitle(title, 'titleForHistory', mainDiv);

    let citationDiv = $(`<div class="mt-3">${citation}<\div>`);
    mainDiv.append(citationDiv);

    let pubMedA = createAnchorElement('PubMed', url);
    let pubMedDiv = $(`<div class="mt-3">View in: </div>`);
    pubMedDiv.append(pubMedA);
    mainDiv.append(pubMedDiv);
}
function emitSubjects(data, mainDiv) {
    emitPublicationHelper(data, mainDiv, 'subject areas', 'DescriptorName')
}

function emitAuthors(data, mainDiv) {
    emitPublicationHelper(data, mainDiv, 'authors with profiles', 'DisplayName')
}
function emitPublicationHelper(data, mainDiv, subTitle, displayProperty) {
    let theDiv = $(`<div class="bordCcc mt-3 p-2"></div>`);
    mainDiv.append(theDiv);

    divSpanifyTo(subTitle, theDiv, 'divTitleSpan', 'mb-2');
    for (let i=0; i<data.length; i++) {
        let item = data[i];

        let anchorDiv = $('<div></div>');
        theDiv.append(anchorDiv);

        let anchor = createAnchorElement(item[displayProperty], URL);
        anchorDiv.append(anchor);
    }
}

