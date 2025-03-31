
const SimilarsTab = Object.freeze({
    List: Symbol("List"),
    Map: Symbol("Map"),
    Details: Symbol("Details")
});

async function setupSimilars() {
    let [jsonArray, lhsModules, rhsModules] = await commonSetupWithJson();
    setupScrolling(null, true);

    setupExploreNetworks(rhsModules);
    await mainParse(jsonArray, lhsModules, rhsModules);
}
function mainParse(moduleJson, lhsModules, rhsModules) {
    emitTopAndTabs({
        numThingsKey:   gSimilars.similarsKey,
        description:    'Similar people share similar sets of concepts, but are not necessarily co-authors.',
        thingsLabel:    "Similar People",
        thingTabs:      gSimilars.similarsTabs,
        harvestTabSyms:  harvestSimilarsTabInfoFromUrl,
        target:         createOrGetTopLhsDiv()  });

    let topLhsDiv = $('#topLhsDiv');
    innerCurtainsDown(topLhsDiv);

    rememberArraySizeOfJsonModule(moduleJson, "SimilarPeople.Connection", gSimilars.similarsKey); // if in Json remember how many

    // expecting exactly one lhs module
    let lhsModuleJson = lhsModules[0];
    let data = lhsModuleJson.ModuleData;

    let target = $('#topLhsDiv');
    adjustActiveSimilarsTab();

    let result;
    switch (gSimilars.whichTabSym) {
        case SimilarsTab.List:
            result = similarsListParser(data);
            break;
        case SimilarsTab.Map:
            result = mapParse(data, 'similar people');
            break;
        case SimilarsTab.Details:
            result = similarsDetailsParser(data);
            break;
    }

    target.append(result);

    innerCurtainsUp(topLhsDiv);
}
function harvestSimilarsTabInfoFromUrl() {
    let myUrl = window.location.href;

    if (myUrl.match(/similarTo(\/list)?(#.*)?$/i)) { // #.* handles post-scroll-top
        gSimilars.whichTabSym = SimilarsTab.List;
    }
    else if (myUrl.match(/similarTo.map/i)) {
        gSimilars.whichTabSym = SimilarsTab.Map;
    }
    else if (myUrl.match(/similarTo.details/i)) {
        gSimilars.whichTabSym = SimilarsTab.Details;
    }

    toSession(gSimilars.whichTabKey, {url: myUrl, label: gSimilars.whichTabSym.description});
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
    }
    else if (myUrl.match(/similarTo.map/i)) {
        gSimilars.whichTabDiv = toMap;
    }
    else if (myUrl.match(/similarTo.details/i)) {
        gSimilars.whichTabDiv = toDetails;
    }

    gSimilars.whichTabDiv.addClass("active");
    gSimilars.whichTabDiv.removeAttr("href");
}
gSimilars.similarsTabs = createFlavorTabs(
    ['List', 'Map', 'Details']);
