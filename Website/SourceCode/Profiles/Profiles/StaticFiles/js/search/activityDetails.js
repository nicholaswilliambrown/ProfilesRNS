async function setupActivityDetails() {
    await setupPageStub();

    let contentDiv = $('#contentDiv');
    let mainDiv = $('#mainDiv');
    moveContentTo(contentDiv, mainDiv);
    mainDiv.addClass(gCommon.mainDivClasses);

    let scrollDiv = new InfiniteScrollDiv(
        getMoreActivities,
        contentDiv,
        'scrollDiv pt-1',
        emitActivityData,
        false);
    await scrollDiv.init(scrollDiv); // methods do not access the correct 'this'
}
async function getMoreActivities() {
    let dataUrl = activityUrlFromSchema(
        gSearch.activityDetailsUrl,
        gSearch.activityDetailsCount,
        gSearch.activityCurrentHighId);

    let activities = await getJsonData(dataUrl);
    console.log("========> activityData", activities);

    return activities;
}
function emitActivityData(activities, target) {
    let colspecs = [
        newColumnSpec(`${gCommon.cols1or12} ps-0 pe-2 d-flex justify-content-start`),
        newColumnSpec(`${gCommon.cols2or12} pe-2 d-flex justify-content-start`),
        newColumnSpec(`${gCommon.cols9or12} d-flex justify-content-start `)
    ];

    let activityLogId;
    for (let i=0; i<activities.length; i++) {
        let activity = activities[i];
        emitOneActivity(activity, colspecs, target);
    }
    gSearch.activityCurrentHighId = activityLogId; // final id is new high-sentinel
}
function emitOneActivity(activity, colspecs, target) {
    let activityLogId = activity.activityLogID;

    let row = makeRowWithColumns(target, activityLogId, colspecs, "ms-0 ps-0");
    let col1 = row.find(`#${activityLogId}Col0`);
    let col2 = row.find(`#${activityLogId}Col1`);
    let col3 = row.find(`#${activityLogId}Col2`);

    let blurb = emitActivityBlurb(activity);
    if (blurb) { // empty if could not cook blurb from activity
        let {thumbnail, nameDateDiv} = activityThumbnailAndDate(activity);
        col1.append(thumbnail);
        col2.append(nameDateDiv);

        divSpanifyTo(blurb, col3, 'recentUpdateBlurb', 'ps-3');
        target.append($('<hr class="tightHr"/>'));
    }

}