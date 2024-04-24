const CoauthorTab = Object.freeze({
    List: Symbol("List"),
    Map: Symbol("Map"),
    Radial: Symbol("Radial"),
    Cluster: Symbol("Cluster"),
    Timeline: Symbol("Timeline"),
    Details: Symbol("Details")
});


async function setupCoauthors() {
    let [jsonArray, lhsModules, rhsModules] = await commonSetupWithJson(compareLhsModules);
    mainParse(jsonArray, lhsModules, rhsModules);
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

    if (myUrl.match(/coauthors(\/list)?$/i)) {
        gCoauthor.whichTabDiv = toList;
        gCoauthor.whichTabSym = CoauthorTab.List;
    }
    else if (myUrl.match(/coauthors.details/i)) {
        gCoauthor.whichTabDiv = toDetails;
        gCoauthor.whichTabSym = CoauthorTab.Details;
    }
    else if (myUrl.match(/coauthors.cluster/i)) {
        gCoauthor.whichTabDiv = toCluster;
        gCoauthor.whichTabSym = CoauthorTab.Cluster;
    }
    else if (myUrl.match(/coauthors.radial/i)) {
        gCoauthor.whichTabDiv = toRadial;
        gCoauthor.whichTabSym = CoauthorTab.Radial;
    }
    else if (myUrl.match(/coauthors.map/i)) {
        gCoauthor.whichTabDiv = toMap;
        gCoauthor.whichTabSym = CoauthorTab.Map;
    }
    else if (myUrl.match(/coauthors.timeline/i)) {
        gCoauthor.whichTabDiv = toTimeline;
        gCoauthor.whichTabSym = CoauthorTab.Timeline;
    }

    gCoauthor.whichTabDiv.addClass("active");
    gCoauthor.whichTabDiv.removeAttr("href");
}

function mainParse(coauthJson, lhsModules, rhsModules) {
    rememberArraySizeOfJsonModule(coauthJson, "Coauthor.Connection", gCoauthor.coAuthsKey); // if in Json remember how many

    let whoAreCoauthsDiv = $(`<div id="whoAreCoauths">
        ${gCoauthor.coauthorsWithDash} are people in Profiles who have published together.</div>`);
    emitTopOfLhsAndExplores({
                                numThingsKey:    gCoauthor.coAuthsKey,
                                descriptionDiv:  whoAreCoauthsDiv,
                                thingsLabel:     gCoauthor.coauthorsWithDash,
                                thingTabs:       gCoauthor.coauthorTabs,
                                adjustTabs:      adjustActiveCoauthTab,
                                rhsModules:      rhsModules  });

    // expecting exactly one lhs module
    let lhsModuleJson = lhsModules[0];

    let target = $('#topLhsDiv');
    switch (gCoauthor.whichTabSym) {
        case CoauthorTab.List:
            listParse(target, lhsModuleJson);
            break;
        case CoauthorTab.Details:
            detailsParse(target, lhsModuleJson);
            break;
        case CoauthorTab.Cluster:
            moveContentByIdTo('moveableContentDiv', target);
            clusterParse(lhsModuleJson);
            break;
        case CoauthorTab.Radial:
            moveContentByIdTo('moveableContentDiv', target);
            radialParse(target, lhsModuleJson);
            break;
        case CoauthorTab.Map:
            mapParse(lhsModuleJson, true, gCoauthor.coauthorsWithDash.toLowerCase());
            break;
        case CoauthorTab.Timeline:
            target.append(gCoauthor.coauthorTimelineContentDiv);
            timelineParse(lhsModuleJson,
                {       dataField: 'People',
                    numPubsField: 'PublicationCount',
                    nameField: 'FirstLast2',
                    urlField: 'Person2URL'});
            break;
    }
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


