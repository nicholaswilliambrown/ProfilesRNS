async function setupConceptPage() {
    let [json] = await commonSetupWithJson();
    // page json is also available in global: g.pageJSON

    emitLhs(json);
    emitRhs(json);
}
function emitRhs(json) {
    let similarConcepts = getModuleData(json, 'Concept.SimilarConcept');

    let target = $('#modules-right-div');

    divSpanifyTo('Related Networks', target, 'boldCrimson');
    target.append($('<hr class="tightHr"/>'));

    emitSimilarConcepts(target, similarConcepts);
    //     when json is ready:
    // target.append($('<hr class="tightHr"/>'));
    // emitRelatedPeople();
    // target.append($('<hr class="tightHr"/>'));
    // emitTopJournals();
}
function emitSimilarConcepts(target, similarConcepts) {
    similarConcepts = sortArrayViaSortLabel(similarConcepts, 'SortOrder');

    let headerDiv = divSpanifyTo('Similar Concepts ',
        target, null, 'explore_title')

    let info = $('<img src="/StaticFiles/img/common/info.png" class="noBorder">');
    headerDiv.append(info);

    let blurbDiv = $('<div class="exploreBlurbDiv">' +
        'Similar concepts derived from published works.</div>');
    target.append(blurbDiv);

    blurbDiv.hide();
    info.on('click', function() {
        toggleVisibility(blurbDiv);
    });

    for (let i=0; i<similarConcepts.length; i++) {
        let concept = similarConcepts[i];
        let a = createAnchorElement(concept.DescriptorName, concept.URL);
        let div = $('<div></div>');
        target.append(div);
        div.append(a);
    }
}
function emitLhs(json) {
    let generalInfo = getModuleData(json, 'Concept.GeneralInfo');
    let publicationsData = getModuleData(json, 'Concept.Publications');

    let target = $('#modules-left-div');

    emitTopItems(generalInfo, target);
    emitMeshInfo(generalInfo, target);
    emitPublications(publicationsData, target);
}
function emitTopItems(data, target) {
    let title = data.DescriptorName;

    emitAndHistoricizeTitle(title, 'titleForHistory', target);

    emitTopBlurb(title, target);
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
function emitMeshInfo(data, target) {
    let title = data.DescriptorName;

    let boxDiv = emitBoxedInfoHelper(data,
                                        target,
                                'MeSH information',
                            'DescriptorName');
    let boxDiv2 = $('<div id="meshBox2" class="mt-1 mb-2"></div>');

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
        newColumnSpec(`${gCommon.cols3or12}`, meshMoreGeneral),
        newColumnSpec(`${gCommon.cols3or12}`, meshRelated),
        newColumnSpec(`${gCommon.cols3or12}`, meshMoreSpecific)
    ];
    makeRowWithColumns(boxDiv, "meshTabs", colSpecs, "mb-2");
    boxDiv.append(boxDiv2);

    // emit content for under the buttons
    boxDiv2.find('.meshDefinitionContent').append(data.DescriptorDefinition);

    // wide and narrow versions of the details
    emitDetails(boxDiv2.find('.meshDetailsContent'), data, true);
    emitDetails(boxDiv2.find('.meshDetailsContent'), data, false);

    emitConceptsTree(boxDiv2.find('.meshMoreGeneralContent'),
        data.ParentDescriptors, title, "more general than");
    emitConceptsTree(boxDiv2.find('.meshMoreSpecificContent'),
        data.ChildDescriptors, title, "more specific than");
    emitConceptsTree(boxDiv2.find('.meshRelatedContent'),
        data.SiblingDescriptors, title, "related to");

    meshDefinition.find('button').addClass("ps-0");
    meshDefinition.find('button').click();
}
function emitDetails(target, data, wideVsNarrow) {
    let col0ExtraClasses;
    let col1ExtraClasses;
    let hideShowDiv;
    let wideNarrowSuffix = wideVsNarrow ? 'Wide' : 'Narrow'

    if (wideVsNarrow) {
        col0ExtraClasses = 'text-end';
        col1ExtraClasses = 'text-start';
        hideShowDiv = $(`<div class="${gCommon.hideXsSmallShowOthers}"></div>`);
    }
    else {
        col0ExtraClasses = 'text-start';
        col1ExtraClasses = 'ps-4';
        hideShowDiv = $(`<div class="${gCommon.showXsSmallHideOthers}"></div>`);
    }
    target.append(hideShowDiv);

    let colSpecs = [
        newColumnSpec(`${gCommon.cols2or12} ${col0ExtraClasses}`),
        newColumnSpec(`${gCommon.cols2or12} ${col1ExtraClasses}`),
        newColumnSpec(`${gCommon.cols8or12}`)
        ];

    let rowId = `descriptorID${wideNarrowSuffix}`;
    let row = makeRowWithColumns(hideShowDiv, rowId, colSpecs);
    row.find(`#${rowId}Col0`).html('Descriptor ID');
    row.find(`#${rowId}Col1`).html(data.DescriptorID);

    rowId = `meshNums${wideNarrowSuffix}`;
    row = makeRowWithColumns(hideShowDiv, rowId, colSpecs);
    let numListDiv = $('<div id="numListDiv"></div>');
    row.find(`#${rowId}Col0`).html('MeSH Number(s)');
    row.find(`#${rowId}Col1`).append(numListDiv);
    let meshNums = data.TreeNumberList;
    for (let i=0; i<meshNums.length; i++) {
        divSpanifyTo(meshNums[i].TreeNumber, numListDiv);
    }

    rowId = `terms${wideNarrowSuffix}`;
    row = makeRowWithColumns(hideShowDiv, rowId, colSpecs);
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
function emitConceptsTree(target, data, title, blurbEndish) {
    let initialPreSpace = "";
    let preSpace;
    let prefix = "---"; // will not match any tree code
    let numPrefixDots;

    let blurb = `Below are MeSH descriptors whose meaning is 
                    ${blurbEndish} "${title}".`;
    divSpanifyTo(blurb, target, null, "mb-2");

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
            if (treeNum.match(/^\w\d.*/)) { // initial letter followed by num acts like a dot
                indent++;
            }
            preSpace = initialPreSpace + "&nbsp;&nbsp;".repeat(indent);
        }

        let itemDiv = $('<div></div>');
        target.append(itemDiv);

        let name = item.DescriptorName;
        let titleIsName = false;
        if (name == title) {
            itemDiv.addClass('bold'); // current item (title) stands out
            titleIsName = true;
        }
        let text = `${preSpace} ${name} `;

        if (item.NodeURI && ! titleIsName) { // link if possible, but not current
            let a = createAnchorElement(text, item.NodeURI);
            itemDiv.append(a);
        }
        else {
            let span = spanify(text);
            itemDiv.append(span);
        }
        // bracketed code
        let codeSpan = spanify( ` [${treeNum}]`);
        itemDiv.append(codeSpan);
    }
}
function emitPublications(data, target) {
    let boxDiv = emitBoxedInfoHelper(data, target, 'publications', 'DisplayName');

    let boxDiv2 = $('<div id="pubBoxDiv2" class="mt-1 mb-2"></div>');

    let timeline = createNavItemDivWithContent(
        "pubTimeline", "Timeline", "pubInfo", boxDiv2);
    let recent = createNavItemDivWithContent(
        "pubRecent", "Most Recent", "pubInfo", boxDiv2);

    let headerDiv = $('<div class="d-flex align-items-center">|</div>');
    boxDiv.append(headerDiv);
    headerDiv.prepend(timeline);
    headerDiv.append(recent);

    boxDiv.append(boxDiv2);

    emitTimeline(data, boxDiv2.find('.pubTimelineContent'));
    emitMostRecent(data, boxDiv2.find('.pubRecentContent'));

    timeline.find('button').addClass("ps-0");
    timeline.find('button').click();
}
function emitMostRecent(data, target) {
    data = data[0].Publications;

    divSpanifyTo(
        'Below are the most recent publications written about "Keloid" by people in Profiles.',
        target, null, "mt-2 mb-2");

    let ol = $('<ol></ol>');
    target.append(ol);

    let numPubs = data.length;
    for (let i=0; i<numPubs; i++) {
        let item = data[i];
        let li = $(`<li>${item.prns_informationResourceReference}</li>`);
        ol.append(li);

        let pubMedUrl = gConnections.pubMedUrlSchema.replace(gCommon.schemaPlaceholder, item.bibo_pmid);
        let div = $('<div class="d-inline-block mt-1 mb-1">View in: </div>');
        let a = createAnchorElement('PubMed', pubMedUrl);
        div.append(a);
        ol.append(div);

        if (i != numPubs-1) {
            let hr = $('<hr class="tightHr"/>');
            ol.append(hr);
        }
    }
}
function emitTimeline(data, target) {
    divSpanifyTo("timeline", target);

}

function emitBoxedInfoHelper(data, target, subTitle, displayProperty) {
    let theDiv = $(`<div class="box1 bordCcc mt-3 p-2"></div>`);
    target.append(theDiv);

    divSpanifyTo(subTitle, theDiv, 'divTitleSpan', 'mb-2');
    return theDiv;
}

