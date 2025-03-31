const ConceptsTab = Object.freeze({
    Cloud: Symbol("Cloud"),
    Categories: Symbol("Categories"),
    Timeline: Symbol("Timeline"),
    Details: Symbol("Details")
});

async function setupResearchAreas() {
    let [jsonArray, lhsModules, rhsModules] = await commonSetupWithJson();

    setupScrolling();

    setupExploreNetworks(rhsModules);
    await mainParse(jsonArray, lhsModules);
}

function mainParse(conceptsJson, lhsModules) {
    emitTopAndTabs({
        numThingsKey:   gConcepts.conceptsKey,
        description:    "Concepts are derived automatically from a person\'s publications.",
        thingsLabel:    "Concepts",
        thingTabs:      gConcepts.conceptsTabs,
        harvestTabSyms:  harvestConceptTabInfoFromUrl,
        target:         createOrGetTopLhsDiv()
    });

    let target = $('#topLhsDiv');
    let mainRow = getMainModuleRow();

    let useInnerCurtain = gConcepts.whichTabSym == ConceptsTab.Timeline;
    if (useInnerCurtain) {
        let preTop = createOrGetPreTop(target);
        preTop.addClass('hideTilReady');
        target.append(gConcepts.conceptsTimelineContentDiv);
    }
    let untilReady = target.find('.hideTilReady');
    let continuingCurtain = useInnerCurtain ? untilReady : mainRow;

    innerCurtainsDown(continuingCurtain);

    rememberArraySizeOfJsonModule(conceptsJson, "Person.HasResearchArea", gConcepts.conceptsKey); // if in Json remember how many

    // expecting exactly one lhs module
    let lhsModuleJson = lhsModules[0];
    let data = lhsModuleJson.ModuleData;

    adjustActiveConceptsTab();

    let result;
    switch (gConcepts.whichTabSym) {
        case ConceptsTab.Cloud:
            result = conceptsCloudParser(data);
            break;
        case ConceptsTab.Categories:
            result = conceptsCategoryParser(data);
            break;
        case ConceptsTab.Timeline:
            result = timelineParse(lhsModuleJson,
                {
                        dataField: 'Concepts',
                        numPubsField: 'NumPubs',
                        nameField: 'MeshHeader',
                        urlField: 'URL'});
            break;
        case ConceptsTab.Details:
            result = conceptsDetailsParser(data);
            break;
    }

    target.append(result);

    innerCurtainsUp(continuingCurtain);
}

function harvestConceptTabInfoFromUrl() {
    let myUrl = window.location.href;

    if (myUrl.match(/researchAreas(\/cloud)?(#.*)?$/i)) { // #.* handles post-scroll-top
        gConcepts.whichTabSym = ConceptsTab.Cloud;
    }
    else if (myUrl.match(/researchAreas.categories/i)) {
        gConcepts.whichTabSym = ConceptsTab.Categories;
    }
    else if (myUrl.match(/researchAreas.timeline/i)) {
        gConcepts.whichTabSym = ConceptsTab.Timeline;
    }
    else if (myUrl.match(/researchAreas.details/i)) {
        gConcepts.whichTabSym = ConceptsTab.Details;
    }

    toSession(gConcepts.whichTabKey, {url: myUrl, label: gConcepts.whichTabSym.description});
}
function adjustActiveConceptsTab() {
    let myUrl = window.location.href;

    let researchAreas = "ResearchAreas";

    let urlPrefix = myUrl.replace(/researchAreas.*/i, "");
    let toCloud = $('#navToCloud');
    let toCategories = $('#navToCategories');
    let toTimeline = $('#navToTimeline');
    let toDetails = $('#navToDetails');

    toCloud.attr("href", urlPrefix + `${researchAreas}/cloud`);
    toCategories.attr("href", urlPrefix + `${researchAreas}/categories`);
    toTimeline.attr("href", urlPrefix + `${researchAreas}/timeline`);
    toDetails.attr("href", urlPrefix + `${researchAreas}/details`);

    if (myUrl.match(/researchAreas(\/cloud)?(#.*)?$/i)) { // #.* handles post-scroll-top
        gConcepts.whichTabDiv = toCloud;
    }
    else if (myUrl.match(/researchAreas.categories/i)) {
        gConcepts.whichTabDiv = toCategories;
    }
    else if (myUrl.match(/researchAreas.timeline/i)) {
        gConcepts.whichTabDiv = toTimeline;
    }
    else if (myUrl.match(/researchAreas.details/i)) {
        gConcepts.whichTabDiv = toDetails;
    }

    gConcepts.whichTabDiv.addClass("active");
    gConcepts.whichTabDiv.removeAttr("href");
}

gConcepts.conceptsTabs = createFlavorTabs(
    ['Cloud', 'Categories', 'Timeline', 'Details']);

gConcepts.conceptsTimelineBlurb =
    `The timeline below shows the dates (blue tick marks) of publications associated with 
    <span class="theTimelinePerson">our person</span>'s top concepts. 
    The average publication date for each concept is shown as a red circle, 
    illustrating changes in the primary topics that 
    <span class="theTimelinePerson">our person</span> has written about over time.`;
gConcepts.conceptsTimelineContentDiv = createTimelineDiv(gConcepts.conceptsTimelineBlurb);
