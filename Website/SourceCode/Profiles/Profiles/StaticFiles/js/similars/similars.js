const SimilarsTab = Object.freeze({
    List: Symbol("List"),
    Map: Symbol("Map"),
    Details: Symbol("Details")
});

async function setupSimilars() {
    let [jsonArray, lhsModules, rhsModules] = await commonSetupWithJson(compareLhsModules);
    setupScrolling();

    mainParse(jsonArray, lhsModules, rhsModules);
}
function mainParse(moduleJson, lhsModules, rhsModules) {
    rememberArraySizeOfJsonModule(moduleJson, "SimilarPeople.Connection", gSimilars.similarsKey); // if in Json remember how many

    let whatAreSimilarsDiv = $('<div class="mb-3" id="whatAreSimilars">' +
        'Similar people share similar sets of concepts, but are not necessarily co-authors.</div>');

    emitTopOfLhsAndExplores({
        numThingsKey:   gSimilars.similarsKey,
        descriptionDiv: whatAreSimilarsDiv,
        thingsLabel:    "Similar People",
        thingTabs:      gSimilars.similarsTabs,
        adjustTabs:     adjustActiveSimilarsTab,
        rhsModules:     rhsModules  });

    // expecting exactly one lhs module
    let lhsModuleJson = lhsModules[0];
    let data = lhsModuleJson.ModuleData;

    let target = $('#topLhsDiv');
    let result;
    switch (gSimilars.whichTabSym) {
        case SimilarsTab.List:
            result = similarsListParser(data);
            break;
        case SimilarsTab.Map:
            result = mapParse(data, false, 'similar people');
            break;
        case SimilarsTab.Details:
            result = similarsDetailsParser(data);
            break;
    }

    target.append(result);
}
function adjustActiveSimilarsTab() {
    let myUrl = window.location.href;

    let similarTo = "SimilarTo";

    let urlPrefix = myUrl.replace(/similarTo.*/i, "");
    let toList = $('#navToList');
    let toMap = $('#navToMap');
    let toDetails = $('#navToDetails');

    // explicit /list is broken....  toList.attr("href", urlPrefix + `${similarTo}/list`);
    toList.attr("href", urlPrefix + `${similarTo}`);
    toMap.attr("href", urlPrefix + `${similarTo}/map`);
    toDetails.attr("href", urlPrefix + `${similarTo}/details`);

    if (myUrl.match(/similarTo(\/list)?(#.*)?$/i)) { // #.* handles post-scroll-top
        gSimilars.whichTabDiv = toList;
        gSimilars.whichTabSym = SimilarsTab.List;
    }
    else if (myUrl.match(/similarTo.map/i)) {
        gSimilars.whichTabDiv = toMap;
        gSimilars.whichTabSym = SimilarsTab.Map;
    }
    else if (myUrl.match(/similarTo.details/i)) {
        gSimilars.whichTabDiv = toDetails;
        gSimilars.whichTabSym = SimilarsTab.Details;
    }

    gSimilars.whichTabDiv.addClass("active");
    gSimilars.whichTabDiv.removeAttr("href");
}
gSimilars.similarsTabs = createFlavorTabs(
    ['List', 'Map', 'Details']);
