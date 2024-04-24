async function setupActivityDetails() {
    await setupPageStub();

    let contentDiv = $('#contentDiv');
    let mainDiv = $('#mainDiv');
    moveContentTo(contentDiv, mainDiv);
    mainDiv.addClass(gCommon.mainDivClasses);

    let scrollDiv = new ScrollDiv(
        getMoreActivities,
        contentDiv,
        'scrollDiv pt-1',
        emitActivityData,
        false);
}
async function getMoreActivities() {
    let dataUrl = activityUrlFromSchema(
        gImpl.activityDetailsUrl,
        gSearch.activityDetailsCount,
        gSearch.activityCurrentHighId);

    let activities = await getJsonData(dataUrl);
    console.log("========> activityData", activities);

    return activities;
}
function activityUrlFromSchema(urlSchema, desiredCount, lastId) {
    let result = urlSchema
        .replace(gCommon.schemaPlaceholder, desiredCount)
        .replace(gCommon.schemaPlaceholder2, lastId);
    return result;
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
        activityLogId = activity.activityLogID;

        let row = makeRowWithColumns(target, activityLogId, colspecs, "ms-0 ps-0");
        let col1 = row.find(`#${activityLogId}Col0`);
        let col2 = row.find(`#${activityLogId}Col1`);
        let col3 = row.find(`#${activityLogId}Col2`);

        let {thumbnail, nameDateDiv} = activityThumbnailAndDate(activity);
        col1.append(thumbnail);
        col2.append(nameDateDiv);
        emitActivityBlurb(activity, col3);

        target.append($('<hr class="tightHr"/>'));
    }
    gSearch.activityCurrentHighId = activityLogId; // final id is new high-sentinel
}