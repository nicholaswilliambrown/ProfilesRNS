function emitConnectionTopStuff(params) {
    target =        params.target;
    displayName =   params.displayName;
    name =          params.text1;
    nameUrl =       params.url1;
    name2 =         params.text2;
    name2Url =      params.url2;
    pid =           params.pid;
    weight =        params.weight;
    lhsBlurb =      params.lhsBlurb;

    gCommon.displayName = displayName;

    let backUrl = gConnections.personDetailsUrlSchema.replace(gCommon.schemaPlaceholder, pid);

    emitCommonTopOfLhs(target, `${name} to ${name2}`, 0,
        backUrl, gConnections.details);

    emitConnectionLhsBlurb(target, lhsBlurb);

    let connectionBox = emitConnectionBox(  name, nameUrl,
        name2, name2Url,
        weight);
    target.append(connectionBox);

    let rhsDiv = $('#modules-right-div');
    moveContentByIdTo('moveableContentDiv', rhsDiv);
}
function emitConnectionBox(lhsText, lhsUrl, rhsText, rhsUrl, strength) {
    let boxDiv = $('<div class="boxDiv pt-2 pb-2"></div>');

    let lhsA = createAnchorElement(lhsText, lhsUrl);
    let rhsA = createAnchorElement(rhsText, rhsUrl);

    let colspecs = [
        newColumnSpec(`${gCommon.cols3or12} alignMiddle d-flex justify-content-end`),
        newColumnSpec(`${gCommon.cols6or12} p-0 alignMiddle d-flex justify-content-center`),
        newColumnSpec(`${gCommon.cols3or12} alignMiddle d-flex justify-content-start`)
    ];

    let rowId = 'connectionBoxTable';
    let row = makeRowWithColumns(boxDiv, rowId, colspecs, "ms-0 me-0");

    let middleColumn = connectionMiddleColumn(strength);

    row.find(`#${rowId}Col0`).append(lhsA);
    row.find(`#${rowId}Col1`).append(middleColumn);
    row.find(`#${rowId}Col2`).append(rhsA);

    return boxDiv;
}
function connectionMiddleColumn(strength) {
    let result = $('<div class="w92"></div>');

    let doubleArrow = makeArrowedConnectionLine();

    result.append($('<div class="d-flex justify-content-center">Connection Strength</div>'));
    result.append(doubleArrow);
    result.append($(`<div class="d-flex justify-content-center">${strength}</div>`));
    return result;
}
function emitConnectionLhsBlurb(target, content) {
    let blurbContent = $(`<div class="mb-1" id="blurbContent">${content}</div>`);

    target.append(blurbContent);
}


