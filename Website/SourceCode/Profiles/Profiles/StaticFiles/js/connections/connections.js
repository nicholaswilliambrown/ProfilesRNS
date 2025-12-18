function emitConnectionTopStuff(params) {
    let target =        params.target;
    let displayName =   params.displayName;
    let name =          params.text1;
    let nameUrl =       params.url1;
    let name2 =         params.text2;
    let name2Url =      params.url2;
    let weight =        params.weight;
    let lhsBlurb =      params.lhsBlurb;
    let subtitle =      params.subtitle;
    let backUrl =       params.backUrl;
    let backLabel =     params.backLabel;

    if (! weight) {
        weight = gCommon.NA;
    }
    gCommon.displayName = displayName;

    backLabel = backLabel ? backLabel : gConnections.details;
    emitCommonTopOfLhs(target, `${subtitle}`, 0,
        backUrl, backLabel, getPersonDisplayName());

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
    let blurbContent = $(`<div class="mb-1 mt-2" id="blurbContent">${content}</div>`);

    target.append(blurbContent);
}


