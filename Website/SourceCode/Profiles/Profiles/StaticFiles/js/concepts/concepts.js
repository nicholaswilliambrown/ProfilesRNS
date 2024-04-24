const ConceptsTab = Object.freeze({
    Cloud: Symbol("Cloud"),
    Categories: Symbol("Categories"),
    Timeline: Symbol("Timeline"),
    Details: Symbol("Details")
});

async function setupConcepts() {
    let [jsonArray, lhsModules, rhsModules] = await commonSetupWithJson(compareLhsModules);
    setupScrolling();

    mainParse(jsonArray, lhsModules, rhsModules);
}
function mainParse(conceptsJson, lhsModules, rhsModules) {
    rememberArraySizeOfJsonModule(conceptsJson, "Person.HasResearchArea", gConcepts.conceptsKey); // if in Json remember how many

    let whatAreConceptsDiv = $('<div class="mb-3" id="whatAreConcepts">' +
        'Concepts are derived automatically from a person\'s publications.</div>');

    emitTopOfLhsAndExplores({                                                    
                                numThingsKey:   gConcepts.conceptsKey,
                                descriptionDiv: whatAreConceptsDiv,
                                thingsLabel:    "Concepts",
                                thingTabs:      gConcepts.conceptsTabs,
                                adjustTabs:     adjustActiveConceptsTab,
                                rhsModules:     rhsModules  });

    // expecting exactly one lhs module
    let lhsModuleJson = lhsModules[0];
    let data = lhsModuleJson.ModuleData;

    let target = $('#topLhsDiv');
    let result;
    switch (gConcepts.whichTabSym) {
        case ConceptsTab.Cloud:
            result = conceptCloudParser(data);
            break;
        case ConceptsTab.Categories:
            result = conceptCategoryParser(data);
            break;
        case ConceptsTab.Timeline:
            target.append(gConcepts.conceptsTimelineContentDiv);
            result = timelineParse(lhsModuleJson,
                {
                        dataField: 'Concepts',
                        numPubsField: 'NumPubs',
                        nameField: 'MeshHeader',
                        urlField: 'URL'});
            break;
        case ConceptsTab.Details:
            result = conceptDetailsParser(data);
            break;
    }

    target.append(result);
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
        gConcepts.whichTabSym = ConceptsTab.Cloud;
    }
    else if (myUrl.match(/researchAreas.categories/i)) {
        gConcepts.whichTabDiv = toCategories;
        gConcepts.whichTabSym = ConceptsTab.Categories;
    }
    else if (myUrl.match(/researchAreas.timeline/i)) {
        gConcepts.whichTabDiv = toTimeline;
        gConcepts.whichTabSym = ConceptsTab.Timeline;
    }
    else if (myUrl.match(/researchAreas.details/i)) {
        gConcepts.whichTabDiv = toDetails;
        gConcepts.whichTabSym = ConceptsTab.Details;
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
