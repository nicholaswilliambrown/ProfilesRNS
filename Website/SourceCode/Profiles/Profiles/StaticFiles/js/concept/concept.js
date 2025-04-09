let fleshyTarget = new Map();

async function setupConceptPage() {
    await commonSetup(true);
    $('#modules-right-div').addClass("passiveNetwork");
    let moduleContentTarget = getMainModuleRow();
    innerCurtainsDown(moduleContentTarget);

    await emitSkeletons();

    let json = await myGetPageJson();

    google.charts.load('current', {'packages':['corechart']});
    google.charts.load('current', {'packages':['bar']});
    google.charts.setOnLoadCallback(async function(){
        await emitDataLhs(json);
        await emitDataRhs(json);
        await $(`.${gCommon.tentative}`).remove(); // failed to materialize

        innerCurtainsUp(moduleContentTarget);
    });
}
function emitSkeletons() {
    emitSkeletonRhs();
    emitSkeletonLhs();
}
function emitSkeletonRhs() {
    let target = $('#modules-right-div');

    divSpanifyTo('Related Networks', target, 'boldNetworks');

    emitRhsSkeleton(target, 'People', 'People who have written about this concept.', 'people');
    emitRhsSkeleton(target, 'Similar Concepts', 'Similar concepts derived from published works.', 'concepts');
    emitRhsSkeleton(target, 'Top Journals', 'Top journals in which articles about this concept have been published.', 'journals');
}
function emitDataRhs(json) {

    let topPeople = findModuleDataByName(json, 'Concept.TopPeople');
    let similarConcepts = findModuleDataByName(json, 'Concept.SimilarConcept');
    let topJournals = findModuleDataByName(json, 'Concept.TopJournals');

    let peopleKey = 'people';
    emitRhsSection({
        data      : topPeople,
        nameField : 'Name',
        sortField : 'Weight',
        reverse   : true,
        innerKey  : peopleKey
    });

    let generalInfo = findModuleDataByName(json, 'Concept.GeneralInfo');
    let thisConceptName = orNaProperty(generalInfo, 'DescriptorName');

    let target = fleshyTarget.get(peopleKey);
    let clickFn = () => minimalPeopleSearchByTerm(thisConceptName);
    emitExploreButton(target, clickFn);

    emitRhsSection({
        data      : similarConcepts,
        nameField : 'DescriptorName',
        sortField : 'SortOrder',
        reverse   : false,
        innerKey  : 'concepts'
    });

    emitRhsSection({
        data      : topJournals,
        nameField : 'Journal',
        sortField : 'Weight',
        reverse   : true,
        innerKey  : 'journals'
    });
}
function emitRhsSkeleton(target, title, blurb, innerKey) {
    let tentativeContainer = tentativizeAndInnerize(target, innerKey, "");

    let headerDiv = $(`<div class="explore_title">${title}</div>`);

    let info = $(`<img src="${gBrandingConstants.jsCommonImageFiles}info.png" class="noBorder">`);
    headerDiv.append(info);

    let blurbDiv = $(`<div class="exploreBlurbDiv">${blurb}</div>`);
    tentativeContainer.prepend(blurbDiv);
    tentativeContainer.prepend(headerDiv);
    tentativeContainer.prepend($('<hr class="tightHr"/>'));

    blurbDiv.hide();
    info.on('click', function() {
        toggleVisibility(blurbDiv);
    });
}
function emitRhsSection(options) {
    let data       = orEmptyList(options.data)      ;
    let nameField  = options.nameField ;
    let sortField  = options.sortField ;
    let reverse    = options.reverse   ;
    let innerKey    = options.innerKey   ;

    let target = fleshyTarget.get(innerKey);
    untentavize(target);

    data = sortArrayViaSortLabel(data, sortField, reverse);

    for (let i=0; i<data.length; i++) {
        let item = data[i];
        let div = $('<div></div>');
        target.append(div);

        let itemDisplay;
        let name = item[nameField];
        if (item.URL) {
            itemDisplay = createAnchorElement(name, item.URL);
        }
        else {
            itemDisplay = spanify(name);
        }
        div.append(itemDisplay);
    }
}
function emitSkeletonLhs() {
    let target = $('#modules-left-div');

    emitTopItemsSkeleton(target, "top", "Title etc.");
    emitMeshInfoSkeleton(target, "mesh", "MeSH Information");
    emitPublicationsSkeleton(target, "pubs", "Publications");
}
function untentavize(elt) {
    elt.closest(`.${gCommon.tentative}`).removeClass(gCommon.tentative);
    elt.parent().find(`.loadInProgress`).remove();
}
function tentativizeAndInnerize(target, innerKey, tempTitle) {
    let tentativeContainer = $(`<div class="${gCommon.tentative}"></div>`);
    let loadingDiv = $(`<div class="loadInProgress">${tempTitle} Loading</div>`);
    let innerDiv = $(`<div class="innerTarget"></div>`);

    target.append(tentativeContainer);
    tentativeContainer.append(loadingDiv);
    tentativeContainer.append(innerDiv);

    fleshyTarget.set(innerKey, innerDiv);

    return tentativeContainer;
}
function emitTopItemsSkeleton(target, innerKey, tempTitle) {
    tentativizeAndInnerize(target, innerKey, tempTitle);
}
function emitMeshInfoSkeleton(target, innerKey, tempTitle) {
    tentativizeAndInnerize(target, innerKey, tempTitle);
}
function emitPublicationsSkeleton(target, innerKey, tempTitle) {
    tentativizeAndInnerize(target, innerKey, tempTitle);
}
function emitDataLhs(json) {
    let generalInfo = findModuleDataByName(json, 'Concept.GeneralInfo');
    let publicationsData = findModuleDataByName(json, 'Concept.Publications');
    let conceptName = orNaProperty(generalInfo, 'DescriptorName');

    emitTopItems(generalInfo, "top");
    emitMeshInfo(generalInfo, "mesh");
    emitPublications(publicationsData, conceptName, "pubs");
}
function emitTopItems(data, innerKey) {
    let target = fleshyTarget.get(innerKey);
    untentavize(target);

    let title = orNaProperty(data, 'DescriptorName');

    emitAndHistoricizeTitle(title, 'titleForHistory', target);

    emitTopBlurb(title, target);
}
function emitMeshInfo(data, innerKey) {
    let target = fleshyTarget.get(innerKey);
    untentavize(target);

    let title = orNaProperty(data, 'DescriptorName');

    let boxDiv = emitBoxedInfoHelper(data, target, 'MeSH information');
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
        "meshMoreSpecific", "More Specific Concepts", "meshInfo", boxDiv2, true);

    let colSpecs = [
        newColumnSpec(`${gCommon.cols2or12} `, meshDefinition),
        newColumnSpec(`${gCommon.cols2or12} `, meshDetails),
        newColumnSpec(`${gCommon.cols3or12} `, meshMoreGeneral),
        newColumnSpec(`${gCommon.cols2or12} `, meshRelated),
        newColumnSpec(`${gCommon.cols3or12} `, meshMoreSpecific)
    ];
    makeRowWithColumns(boxDiv, "meshTabs", colSpecs, "ms-1 mb-2 test");
    boxDiv.append(boxDiv2);

    // emit content for under the buttons
    let definition = orNaProperty(data, 'DescriptorDefinition', "No Definition Found");
    boxDiv2.find('.meshDefinitionContent').append(definition);

    // wide and narrow versions of the details
    emitDetails(boxDiv2.find('.meshDetailsContent'), data, true);
    emitDetails(boxDiv2.find('.meshDetailsContent'), data, false);

    emitConceptsTree(boxDiv2.find('.meshMoreGeneralContent'),
        orNaPropertyList(data, 'ParentDescriptors'), title, "more general than");
    emitConceptsTree(boxDiv2.find('.meshMoreSpecificContent'),
        orNaPropertyList(data, 'ChildDescriptors'), title, "more specific than");
    emitConceptsTree(boxDiv2.find('.meshRelatedContent'),
        orNaPropertyList(data, 'SiblingDescriptors'), title, "related to");

    meshDefinition.find('button').addClass("ps-0");
    meshDefinition.find('button').click();
}
async function emitPublications(data, conceptName, innerKey) {
    data = orEmptyList(data);

    let target = fleshyTarget.get(innerKey);
    untentavize(target);

    let boxDiv = emitBoxedInfoHelper(data, target, 'publications');

    let boxDiv2 = $('<div id="pubBoxDiv2" class="mt-1 mb-2"></div>');

    let timelineBlurb = `This graph shows the total number of publications written about "${conceptName}" 
                            by people in Profiles by year, 
                            and whether "${conceptName}" was a major or minor topic of these publications.`
    let timelineBlurbDiv = $(`<div class="mb-2" id="timelineBlurb">${timelineBlurb}</div>`);
    let timelineButtonDiv = createNavItemDivWithContent(
        'pubTimeline', "Timeline", "pubInfo", boxDiv2, false, timelineBlurbDiv);
    timelineButtonDiv.addClass('bordE');

    let timelineButton = timelineButtonDiv.find('button');
    timelineButton.addClass("ps-2");

    let mostRecent = createNavItemDivWithContent(
        "pubRecent", "Most Recent", "pubInfo", boxDiv2, true);
    let mostRecentButton = mostRecent.find('button');

    let headerDiv = $('<div class="ms-1 d-flex align-items-center"></div>');
    boxDiv.append(headerDiv);
    headerDiv.append(timelineButtonDiv);
    headerDiv.append(mostRecent);

    boxDiv.append(boxDiv2);

    let timelineTargetDiv = boxDiv2.find('.pubTimelineContent');
    await emitTimeline(data, timelineTargetDiv, true);
    await emitTimeline(data, timelineTargetDiv);
    timelineTargetDiv.hide();

    emitMostRecent(data, boxDiv2.find('.pubRecentContent'), conceptName);

    $('button.pubInfo').on('click', function(e){
        $('.pubInfoContent').hide();
        let target = $(e.target);
        let flavor = target.parent().attr('flavor');
        let contentId = flavor + 'Content';
        $(`#${contentId}`).show();
    });

    timelineButton.click();
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
function createNavItemDivWithContent(idBase, title, generalClass, boxDiv, noBordE, preamble) {

    let buttonClass = `${generalClass}NavButton`;
    let generalButtonClass = `p-0 w-100 ${generalClass} ${generalClass}NavButton`;

    let clickFn = (e) => {
        let target = $(e.target);
        if (! target.hasClass('active')) {
            $(`.${generalClass}Content`).hide();
            $(`.${buttonClass}`).removeClass('active').attr('aria-current', false);
            $(`.${buttonClass}`).find('button').removeClass('active').attr('aria-current', false);

            $(`.${idBase}Content`).show();
            target.addClass("active").attr("aria-current", true);
        }
    };

    let buttonDiv = createNavItemDiv(`${idBase}Button`, title, clickFn, generalButtonClass);
    buttonDiv.attr('flavor', idBase);
    let contentDiv = $(`<div id="${idBase}Content" class="ps-1 ${generalClass}Content ${idBase}Content"></div>`);
    if (preamble) {
        contentDiv.append(preamble);
    }
    buttonDiv.addClass("p-2");
    if (! noBordE) {
        buttonDiv.addClass("bordE");
    }

    boxDiv.append(contentDiv);

    return buttonDiv;
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
    row.find(`#${rowId}Col0`).html('<span class="meshLabel">Descriptor ID</span>');
    row.find(`#${rowId}Col1`).html(orNaProperty(data,'DescriptorID'));

    rowId = `meshNums${wideNarrowSuffix}`;
    row = makeRowWithColumns(hideShowDiv, rowId, colSpecs);
    let numListDiv = $('<div id="numListDiv"></div>');
    row.find(`#${rowId}Col0`).html('<span class="meshLabel">MeSH Number(s)</span>');
    row.find(`#${rowId}Col1`).append(numListDiv);
    let meshNums = orNaPropertyList(data, 'TreeNumberList');
    for (let i=0; i<meshNums.length; i++) {
        divSpanifyTo(meshNums[i].TreeNumber, numListDiv);
    }

    rowId = `terms${wideNarrowSuffix}`;
    row = makeRowWithColumns(hideShowDiv, rowId, colSpecs);
    let termListDiv = $('<div id="numListDiv"></div>');
    row.find(`#${rowId}Col0`).html('<span class="meshLabel">Concept/Term(s)</span>');
    row.find(`#${rowId}Col1`).append(termListDiv);
    let meshTerms = orNaPropertyList(data, 'TermList');
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

    let blurb = `Below are MeSH descriptors (if any) whose meaning is 
                    ${blurbEndish} "${title}".`;
    divSpanifyTo(blurb, target, null, "mb-2");

    data = orEmptyList(data);
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
function emitMostRecent(data, target, conceptName) {
    data = orNaPropertyList(data[0], 'Publications');

    divSpanifyTo(
        `Below are the most recent publications written about "${conceptName}" by people in Profiles.`,
        target, null, "ps-2 mt-2 mb-2");

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
    target.hide();
}
async function emitTimeline(data, target, wideVsNarrow) {
    let yearArray = orNaPropertyList(data[0], 'Timeline');

    let classes = wideVsNarrow ? gCommon.hideXsSmallShowOthers :
                            gCommon.showXsSmallHideOthers;
    let responsiveTarget = $(`<div class="${classes}"></div>`);
    target.append(responsiveTarget);

    let chartHeight = wideVsNarrow ? 400 : 200;
    let chartWidth = wideVsNarrow ? 800 : 400;
    await populateTimelineGraph(responsiveTarget, yearArray, chartHeight, chartWidth);
    target.hide();
}

function emitBoxedInfoHelper(data, target, subTitle) {
    let theDiv = $(`<div class="box1 bordCcc mt-3 p-2 MeSHProfileBoxes"></div>`);
    target.append(theDiv);

    divSpanifyTo(subTitle, theDiv, '', 'mb-2 divTitleSpanConcept');
    return theDiv;
}

