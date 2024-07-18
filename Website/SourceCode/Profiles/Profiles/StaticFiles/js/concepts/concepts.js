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
    let generalButtonClass = generalClass + 'NavButton';
    let buttonDiv = createNavItemDiv(`${idBase}Button`, title, null, generalButtonClass);
    let contentDiv = $(`<div id="${idBase}Content" class="${generalClass} ${idBase}Content"></div>`);

    boxDiv.append(contentDiv);

    buttonDiv.on('click', (e) => {
        $(`.${generalClass}`).hide();
        $(`.${generalButtonClass}`).removeClass('active').attr('aria-current', false);

        $(`.${idBase}Content`).show();
        $(e.target).addClass("active").attr("aria-current", true);
    })
    return buttonDiv;
}
function emitMeshInfo(data, mainDiv) {
    let boxDiv = emitBoxedInfoHelper(data,
                                        mainDiv,
                                'MeSH information',
                            'DescriptorName');
    let boxDiv2 = $('<div id="boxDiv2" class="mt-1 mb-2"></div>');

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
    emitConceptsTree(boxDiv2.find('.meshMoreGeneralContent'), data.ParentDescriptors);
    emitConceptsTree(boxDiv2.find('.meshMoreSpecificContent'), data.ChildDescriptors);
    emitConceptsTree(boxDiv2.find('.meshRelatedContent'), data.SiblingDescriptors);

    meshDefinition.find('button').click();
}
function emitDetails(target, data) {
    let colSpecs = [
        newColumnSpec(`${gCommon.cols2or12} d-flex justify-content-end`),
        newColumnSpec(`${gCommon.cols2or12} d-flex justify-content-start`),
        newColumnSpec(`${gCommon.cols8or12}`)
        ];

    let rowId = "descriptorID";
    let row = makeRowWithColumns(target, rowId, colSpecs);
    row.find(`#${rowId}Col0`).html('Descriptor ID');
    row.find(`#${rowId}Col1`).html(data.DescriptorID);

    rowId = "meshNums";
    row = makeRowWithColumns(target, rowId, colSpecs);
    let numListDiv = $('<div id="numListDiv"></div>');
    row.find(`#${rowId}Col0`).html('MeSH Number(s)');
    row.find(`#${rowId}Col1`).append(numListDiv);
    let meshNums = data.TreeNumberList;
    for (let i=0; i<meshNums.length; i++) {
        divSpanifyTo(meshNums[i].TreeNumber, numListDiv);
    }

    rowId = "terms";
    row = makeRowWithColumns(target, rowId, colSpecs);
    let termListDiv = $('<div id="numListDiv"></div>');
    row.find(`#${rowId}Col0`).html('Concept/Term(s)');
    row.find(`#${rowId}Col1`).append(termListDiv);
    let meshTerms = data.TermList
    for (let i=0; i<meshTerms.length; i++) {
        divSpanifyTo(meshTerms[i].Term, termListDiv);
    }
}
function countDots(input) {
    // https://stackoverflow.com/questions/2903542/javascript-how-many-times-a-character-occurs-in-a-string
    return input.replace(/[^\.]/g, "").length;
}
function emitConceptsTree(target, data) {
    let initialPreSpace = "";
    let preSpace;
    let prefix = "---"; // will not match any tree code
    let numPrefixDots;

    for (let i=0; i<data.length; i++) {
        let item = data[i];

        let treeNum = item.TreeNumber;
        if ( ! treeNum.match(`^${prefix}.*`)) {
            preSpace = initialPreSpace;
            prefix = treeNum;
            numPrefixDots = countDots(prefix);
        }
        else { // indent via num dots, or if it's like E0 after E
            let indent = countDots(treeNum) - numPrefixDots;
            if (treeNum.match(`^${prefix}0.*`)) { // attached 0 acts like a dot
                indent = 1;
            }
            preSpace = initialPreSpace + "&nbsp;".repeat(indent);
        }

        let itemDiv = $('<div></div>');
        target.append(itemDiv);

        let text = `${preSpace} ${item.DescriptorName} [${treeNum}]`;

        if (item.NodeURI) {
            let a = createAnchorElement(text, item.NodeURI);
            itemDiv.append(a);
        }
        else {
            let span = spanify(text);
            itemDiv.append(span);
        }
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

