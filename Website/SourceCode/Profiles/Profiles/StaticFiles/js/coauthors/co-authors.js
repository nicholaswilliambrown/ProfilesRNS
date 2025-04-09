
const CoauthorTab = Object.freeze({
    List: Symbol("List"),
    Map: Symbol("Map"),
    Radial: Symbol("Radial"),
    Cluster: Symbol("Cluster"),
    Timeline: Symbol("Timeline"),
    Details: Symbol("Details")
});


async function setupCoauthors() {
    let [jsonArray, lhsModules, rhsModules] =
        await commonSetupWithJson();

    setupExploreNetworks(rhsModules);
    await mainParse(jsonArray, lhsModules, rhsModules);
}

function harvestCoauthTabInfoFromUrl() {
    let myUrl = window.location.href;

    if (myUrl.match(/coauthors(\/list)?$/i)) {
        gCoauthor.whichTabSym = CoauthorTab.List;
    }
    else if (myUrl.match(/coauthors.details/i)) {
        gCoauthor.whichTabSym = CoauthorTab.Details;
    }
    else if (myUrl.match(/coauthors.cluster/i)) {
        gCoauthor.whichTabSym = CoauthorTab.Cluster;
    }
    else if (myUrl.match(/coauthors.radial/i)) {
        gCoauthor.whichTabSym = CoauthorTab.Radial;
    }
    else if (myUrl.match(/coauthors.map/i)) {
        gCoauthor.whichTabSym = CoauthorTab.Map;
    }
    else if (myUrl.match(/coauthors.timeline/i)) {
        gCoauthor.whichTabSym = CoauthorTab.Timeline;
    }

    toSession(gCoauthor.whichTabKey, {url: myUrl, label: gCoauthor.whichTabSym.description});
}
function adjustActiveCoauthTab() {
    let myUrl = window.location.href;

    let coauthors = "CoAuthors";

    let urlPrefix = myUrl.replace(/coauthors.*/i, "");
    let toList = $('#navToList');
    let toDetails = $('#navToDetails');
    let toCluster = $('#navToCluster');
    let toRadial = $('#navToRadial');
    let toMap = $('#navToMap');
    let toTimeline = $('#navToTimeline');

    toCluster.attr("href", urlPrefix + `${coauthors}/Cluster`);
    toRadial.attr("href", urlPrefix + `${coauthors}/Radial`);
    toList.attr("href", urlPrefix + `${coauthors}`);
    toDetails.attr("href", urlPrefix + `${coauthors}/Details`);
    toMap.attr("href", urlPrefix + `${coauthors}/Map`);
    toTimeline.attr("href", urlPrefix + `${coauthors}/Timeline`);

    if (gCoauthor.whichTabSym == CoauthorTab.List) {
        gCoauthor.whichTabDiv = toList;
    }
    else if (gCoauthor.whichTabSym == CoauthorTab.Details) {
        gCoauthor.whichTabDiv = toDetails;
    }
    else if (gCoauthor.whichTabSym == CoauthorTab.Cluster) {
        gCoauthor.whichTabDiv = toCluster;
    }
    else if (gCoauthor.whichTabSym == CoauthorTab.Radial) {
        gCoauthor.whichTabDiv = toRadial;
    }
    else if (gCoauthor.whichTabSym == CoauthorTab.Map) {
        gCoauthor.whichTabDiv = toMap;
    }
    else if (gCoauthor.whichTabSym == CoauthorTab.Timeline) {
        gCoauthor.whichTabDiv = toTimeline;
    }
    gCoauthor.whichTabDiv.addClass("active");
    gCoauthor.whichTabDiv.removeAttr("href");
}

async function mainParse(coauthJson, lhsModules, rhsModules) {
    emitTopAndTabs({
        numThingsKey:    gCoauthor.coAuthsKey,
        description:    `${gCoauthor.coauthorsWithDash} are people in Profiles who have published together.`,
        thingsLabel:     gCoauthor.coauthorsWithDash,
        thingTabs:       gCoauthor.coauthorTabs,
        harvestTabSyms:  harvestCoauthTabInfoFromUrl,
        target:          createOrGetTopLhsDiv()
    });

    let target = $('<div id="parseTarget"></div>');
    $('#topLhsDiv').append(target);

    if (gCoauthor.whichTabSym == CoauthorTab.Timeline) {
        target.append(gCoauthor.coauthorTimelineContentDiv);
    }
    else if (gCoauthor.whichTabSym == CoauthorTab.Cluster) {
        moveContentByIdTo('moveableContentDiv', target);
    }
    else if (gCoauthor.whichTabSym == CoauthorTab.Radial) {
        moveContentByIdTo('moveableContentDiv', target);
    }

    let curtainMsgTarget = $('#tabChoicesDiv');
    let untilReady = $('.hideTilReady');

    let useSpecialCurtain =
        gCoauthor.whichTabSym == CoauthorTab.Cluster ||
        gCoauthor.whichTabSym == CoauthorTab.Timeline ||
        gCoauthor.whichTabSym == CoauthorTab.Radial;

    let curtainTarget = useSpecialCurtain ? untilReady : target;
    innerCurtainsDown(curtainTarget, curtainMsgTarget);

    rememberArraySizeOfJsonModule(coauthJson, "Coauthor.Connection", gCoauthor.coAuthsKey); // if in Json remember how many

    // expecting exactly one lhs module
    let lhsModuleJson = lhsModules[0];

    adjustActiveCoauthTab();

    switch (gCoauthor.whichTabSym) {
        case CoauthorTab.List:
            await listParse(target, lhsModuleJson);
            break;
        case CoauthorTab.Details:
            await detailsParse(target, lhsModuleJson);
            break;
        case CoauthorTab.Cluster:
            await clusterParse(lhsModuleJson);
            break;
        case CoauthorTab.Radial:
            await radialParse(target, lhsModuleJson);
            break;
        case CoauthorTab.Map:
            await mapParse(lhsModuleJson, gCoauthor.coauthorsWithDash.toLowerCase());
            break;
        case CoauthorTab.Timeline:
            await timelineParse(lhsModuleJson,
                {       dataField: 'People',
                    numPubsField: 'PublicationCount',
                    nameField: 'FirstLast2',
                    urlField: 'Person2URL'
                });
            break;
    }

    innerCurtainsUp(curtainTarget);
}

gCoauthor.coauthorTabs = createFlavorTabs(
    ['List', 'Map', 'Radial', 'Cluster', 'Timeline', 'Details']);

gCoauthor.coauthorTimelineBlurb =
    `The timeline below shows the dates (blue tick marks) of
    publications <span class="theTimelinePerson"></span>
    co-authored with other people
    in Profiles. The average publication date
    for each co-author is shown as a red circle,
    illustrating changes in the people that
    <span class="theTimelinePerson"></span>
    has worked with over time.`;
gCoauthor.coauthorTimelineContentDiv = createTimelineDiv(gCoauthor.coauthorTimelineBlurb);


