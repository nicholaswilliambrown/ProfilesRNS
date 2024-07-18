async function setupConceptPage() {
    let [json] = await commonSetupWithJson();
    // page json is also available in global: g.pageJSON

    let generalInfo = getModuleData(json, 'Concept.GeneralInfo');
    let publicationsData = getModuleData(json, 'Concept.Publications');

    let mainDiv = $('#mainDiv');

    emitTopItems(generalInfo, mainDiv);
    emitMeshInfo(generalInfo, mainDiv);
    emitPublications(publicationsData, mainDiv);
}
function emitTopItems(data, mainDiv) {
    let title = data.DescriptorName;

    emitAndHistoricizeTitle(title, 'titleForHistory', mainDiv);

    emitTopBlurb(title, mainDiv);
}
function emitTopBlurb(title, target) {
    let blurb1 = `"${title}" is a descriptor in the National Library of Medicine's 
        controlled vocabulary thesaurus, `;
    let meshA = createAnchorElement(gConcepts.meshSiteText, gConcepts.meshSiteUrl);
    let blurb2 = `. 
        Descriptors are arranged in a hierarchical structure, 
        which enables searching at various levels of specificity.`
    let topBlurbDiv = $(`<div class="mt-3"></div>`);
    topBlurbDiv.append(blurb1)
        .append(meshA)
        .append(blurb2);

    target.append(topBlurbDiv);
}
function createNavItemDivWithContent(idBase, title, generalClass, boxDiv) {
    let buttonDiv = createNavItemDiv(`${idBase}Button`, title);
    let contentDiv = $(`<div id="${idBase}Content" class="${generalClass} ${idBase}Content"></div>`);

    boxDiv.append(contentDiv);

    buttonDiv.on('click', () => {
        $(`.${generalClass}`).hide();
        $(`.${idBase}Content`).show();
    })
    return buttonDiv;
}
function emitMeshInfo(data, mainDiv) {
    let boxDiv = emitBoxedInfoHelper(data,
                                        mainDiv,
                                'MeSH information',
                            'DescriptorName');
    let boxDiv2 = $('<div id="boxDiv2" class="mt-2"></div>');

    let meshDefinition = createNavItemDivWithContent(
        "meshDefinition", "Definition", "meshInfo", boxDiv2);
    let meshDetails = createNavItemDivWithContent(
        "meshDetails", "Details", "meshInfo", boxDiv2);
    let meshMoreGeneral = createNavItemDivWithContent(
        "meshMoreGeneral", "More General Concepts", "meshInfo", boxDiv2);
    let meshRelated = createNavItemDivWithContent(
        "meshRelated", "Related Concepts", "meshInfo", boxDiv2);
    let meshMoreSpecific = createNavItemDivWithContent(
        "meshMoreSpecific", "More Specific Concepts", "meshInfo", boxDiv2);

    let colSpecs = [
        newColumnSpec(`${gCommon.cols1or12}`, meshDefinition),
        newColumnSpec(`${gCommon.cols1or12}`, meshDetails),
        newColumnSpec(`${gCommon.cols2or12}`, meshMoreGeneral),
        newColumnSpec(`${gCommon.cols2or12}`, meshRelated),
        newColumnSpec(`${gCommon.cols2or12}`, meshMoreSpecific)
    ];
    makeRowWithColumns(boxDiv, "meshTabs", colSpecs);
    boxDiv.append(boxDiv2);

    // emit content for under the buttons
    boxDiv2.find('.meshDefinitionContent').append(data.DescriptorDefinition);
    emitDetails(boxDiv2.find('.meshDetailsContent'), data);
    emitConceptsTree(boxDiv2.find('.meshMoreGeneral'), data.ParentDescriptors);
    emitConceptsTree(boxDiv2.find('.meshMoreSpecific'), data.ChildDescriptors);
    emitConceptsTree(boxDiv2.find('.meshMoreGeneral'), data.SiblingDescriptors);
}
function emitDetails(target, data) {
    let colSpecs = [
        newColumnSpec(`${gCommon.cols6or12}`),
        newColumnSpec(`${gCommon.cols6or12}`)
        ];

    let rowId = "descriptorID";
    let row = makeRowWithColumns(target, "${rowId}", colSpecs);
    row.find(`#${rowId}Col0`).html('Descriptor ID');
    row.find(`#${rowId}Col1`).html(data.DescriptorID);

    rowId = "meshNums";
    row = makeRowWithColumns(target, "${rowId}", colSpecs);
    let numListDiv = $('<div id="numListDiv"></div>');
    row.find(`#${rowId}Col1`).html('MeSH Number(s)');
    row.find(`#${rowId}Col1`).append(numListDiv);
    let meshNums = data.TreeNumberList;
    for (let i=0; i<meshNums.length; i++) {
        divSpanifyTo(meshNums[i], numListDiv);
    }

    rowId = "terms";
    row = makeRowWithColumns(target, "${rowId}", colSpecs);
    let termListDiv = $('<div id="numListDiv"></div>');
    row.find(`#${rowId}Col0`).html('Concept/Term(s)');
    row.find(`#${rowId}Col1`).append(termListDiv);
    let meshTerms = data.TermList
    for (let i=0; i<meshTerms.length; i++) {
        divSpanifyTo(meshTerms[i], termListDiv);
    }
}
function emitConceptsTree(target, data) {
    for (let i=0; i<data.length; i++) {
        let item = data[i];

        let anchorDiv = $('<div></div>');
        target.append(anchorDiv);

        let span = spanify(item.TreeNumber);
        target.append(span);
    }
}
function emitPublications(data, mainDiv) {
    let boxDiv = emitBoxedInfoHelper(data, mainDiv, 'publications', 'DisplayName');
}
function emitBoxedInfoHelper(data, mainDiv, subTitle, displayProperty) {
    let theDiv = $(`<div class="box1 bordCcc mt-3 p-2"></div>`);
    mainDiv.append(theDiv);

    divSpanifyTo(subTitle, theDiv, 'divTitleSpan', 'mb-2');
    return theDiv;
}

