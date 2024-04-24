
async function timelineParse(moduleJson, fields) {

    gTimelineTab.colspecs = [
        newColumnSpec(`${gCommon.cols7or12}`),
        newColumnSpec(`${gCommon.cols5or12}`),
    ];

    $('#toDivTimelineText').on("click", viewTimelineText);
    $('#toDivTimeline').on("click", viewTimelineGraph);

    parseTimelineGraph(moduleJson, fields);
    parseTimelineText(moduleJson, fields);

    viewTimelineGraph();
}

function viewTimelineGraph() {
    $('#divTimelineGraph').show();
    $('#divTimelineText').hide();
}
function viewTimelineText() {
    $('#divTimelineText').show();
    $('#divTimelineGraph').hide();
}

function parseTimelineGraph(moduleJson, fields) {
    let graphContainer = $('#timelineGraphInner');

    let graphContent = $('<div class="graphContent"></div>');
    graphContainer.append(graphContent);

    $('.theTimelinePerson').html(getPersonFirstLastName());

    emitTimelineGraph(graphContent, moduleJson, fields);

    // let lhsContent = defaultLeftSideParser(moduleJson, "Timeline");
    // graphContent.append(lhsContent);
}
function parseTimelineText(moduleJson, fields) {

    let connections = moduleJson.ModuleData[fields.dataField];
    let target = $('#timelineTextInner');

    let colspecs = [
        newColumnSpec(`${gCommon.cols3or12} alignMiddle bordE`),
        newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center`),
        newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center`),
        newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center`),
        newColumnSpec(`${gCommon.cols3or12} alignMiddle bordE d-flex justify-content-center`)
    ];

    let rowId = `timelineTextTable`;
    let row = makeRowWithColumns(target, rowId, colspecs, "bordersRow stripe");

    row.find(`#${rowId}Col0`).html('<strong>Name</strong>');
    row.find(`#${rowId}Col1`).html('<strong>Number of Publications</strong>');
    row.find(`#${rowId}Col2`).html('<strong>First Publication Year</strong>');
    row.find(`#${rowId}Col3`).html('<strong>Most Recent Publication Year</strong>');
    row.find(`#${rowId}Col4`).html('<strong>Average Publication Date</strong>');


    colspecs[0] = newColumnSpec(`${gCommon.cols3or12} d-flex justify-content-start bordE`);

    let numItems = connections.length;
    for (let i=0; i<numItems; i++) {
        let conn = connections[i];
        let stripeClass = (i%2 == 1) ? "stripe" : "";

        let numPubs = conn[fields.numPubsField];
        let firstPub = conn.FirstPublicationYear;
        let lastPub = conn.LastPublicationYear;
        let avgPubMonth = conn.AvgMonth + 12 - 1; // 2nd set of 12, 0-index
        let avgPub = `${gCommon.monthNames[avgPubMonth]} ${conn.AvgYear}`;

        // Urls in the form of display/person/xxxx are favored, /profile/pid deprecated
        let url = `${conn[fields.urlField].replace(/Profiles./, "")}`;
        let name = conn[fields.nameField];
        let nameUrl = $(`<a href="${url}">${name}</a>`);

        let rowId = `tl-detail-${i}`;
        row = makeRowWithColumns(target, rowId, colspecs, `ms-1 bordersRow ${stripeClass}`);

        row.find(`#${rowId}Col0`).append(nameUrl);
        row.find(`#${rowId}Col1`).html(numPubs);
        row.find(`#${rowId}Col2`).html(firstPub);
        row.find(`#${rowId}Col3`).html(lastPub);
        row.find(`#${rowId}Col4`).html(avgPub);

        hoverLight(row);
    }
}

function getMinAndMaxYears(moduleJson) {
    let moduleData = moduleJson.ModuleData;
    return [moduleData.MinDisplayYear, moduleData.MaxDisplayYear];
}
function makeSvg(type, props, optTextContent) {
    let result = $(document.createElementNS("http://www.w3.org/2000/svg", type));
    result.attr(props);
    if (optTextContent) {
        result.html(optTextContent);
    }
    return result;
}
function emitTimelineGraph(target, moduleJson, fields) {
    let [rowSvgsDiv, ticksWidth] = emitTimelineGraphTickbar(target, moduleJson);
    populateRowSvgs(rowSvgsDiv, ticksWidth, moduleJson, fields);
}
function emitTimelineGraphTickbar(target, moduleJson) {

    let [firstYear, lastYear] = getMinAndMaxYears(moduleJson);

    let everyYear = Object.keys(everyXthYearLabelsMap(firstYear, lastYear, 1));

    let numTicks = everyYear.length;
    console.log("should show this many ticks: ", numTicks);

    let rowSvgsDiv = $('<div class="timelineSvgRowsDiv"></div>');
    target.append(rowSvgsDiv);

    let rowId = "tls0";
    let legendRow = prepareGraphSuperstructure(rowSvgsDiv, rowId);
    let graphColumn = legendRow.find(`#${rowId}Col0`);

    let timelineLabelsDiv = $(`<div class="timelineLabelsDiv"></div>`);
    let timelineTicksDiv = $(`<div class="timelineTicksDiv"></div>`);
    let timelineTicklineDiv = $('<div class="timelineTicklineDiv"></div>');
    graphColumn.append(timelineLabelsDiv);
    graphColumn.append(timelineTicksDiv);
    graphColumn.append(timelineTicklineDiv);

    let tickSvgs = $(`<svg class="timelineTickSvgs"></svg>`);
    let labelSvgs = $(`<svg class="timelineLabelSvgs"></svg>`);
    timelineLabelsDiv.append(labelSvgs);
    timelineTicksDiv.append(tickSvgs);

    let labelsWidth = timelineLabelsDiv.width();
    let ticksWidth = labelsWidth - gTimelineTab.yearWidth;
    let labelYears = yearLabelsAndSpace(ticksWidth, firstYear, lastYear);

    tickSvgs.css("width", ticksWidth);
    labelSvgs.css("width", labelsWidth);

    let tickGap = ticksWidth / (numTicks - 1);

    let rowsWidth = tickGap * (numTicks - 1);
    timelineTicklineDiv.css("width", `${rowsWidth}px`);

    let tickY = 0;
    let labelY = 15;

    for (let i = 0; i < everyYear.length; i++) {
        let year = everyYear[i];
        let label = labelYears[year];
        let yVal = tickY;
        let xVal = (i * tickGap);

        if (i == everyYear.length - 1) {
            xVal -= 1;
        }
        let oneTick = makeSvg("line",
            {
                x1: xVal, y1: yVal,
                x2: xVal, y2: yVal + 4,
                class: 'oneTick'
            });
        tickSvgs.append(oneTick);

        if (label) {
            let oneLabel = makeSvg("text",
                {x: xVal, y: labelY, class: 'oneLabel'},
                String(label));

            labelSvgs.append(oneLabel);
        }
    }
    tickSvgs.append("<span>sorry no svg</span>");
    return [rowSvgsDiv, ticksWidth];
}
function prepareGraphSuperstructure(rowSvgsDiv, rowId) {

    let row = makeRowWithColumns(rowSvgsDiv, `${rowId}`, gTimelineTab.colspecs, "mt-1");
    return row;
}
function populateRowSvgs(rowSvgsDiv, ticksWidth, moduleJson, fields) {
    let moduleData = moduleJson.ModuleData;
    let connections = moduleData[fields.dataField];

    let midlineY = 6;
    let blipLowY = 2.7;
    let blipHighY = 9.3;
    let circleRadius = 5;
    let svgWidth = ticksWidth - 2; // some buffer on right

    connections.forEach((conn, i) => {
        let rowId = `rowSvg${i}`;
        let row = makeRowWithColumns(rowSvgsDiv, `${rowId}`, gTimelineTab.colspecs,
            "timelineConnRow ms-2 ps-0");
        let xvals = conn.xvals.map(xval => xval.x);
        let oneSvgLine = $("<svg class='timelineConnSvg'></svg>");

        let col0 = row.find(`#${rowId}Col0`);
        col0.append(oneSvgLine);
        col0.addClass("timelineSvgRow");

        let col1 = row.find(`#${rowId}Col1`);
        let url = `${conn[fields.urlField]}`;
        let name = `<a href="${url}">${conn[fields.nameField]}</a>`;

        let wideNameDiv = $(`<div class="${gCommon.hideXsSmMdShowOthers}"></div>`);
        let narrowNameDiv = $(`<div class="${gCommon.showXsSmMdHideOthers}"></div>`);
        let wideName = $(`<div class="d-flex justify-content-start">${name}</div>`);
        let narrowName = $(`<div class="d-flex justify-content-end">${name}</div>`);

        wideNameDiv.append(wideName);
        narrowNameDiv.append(narrowName);
        col1.append(wideNameDiv)
            .append(narrowNameDiv);

        let firstX = Math.min(...xvals);
        let lastX = Math.max(...xvals);
        let midLine = makeSvg("line", {
            x1: svgWidth * firstX, y1: midlineY,
            x2: svgWidth * lastX, y2: midlineY,
            class: "timelineConnMidline"
        });
        oneSvgLine.append(midLine);

        xvals.forEach((xval) => {
            let blipX = svgWidth * xval;
            let blip = makeSvg("line", {
                x1: blipX, y1: blipLowY,
                x2: blipX, y2: blipHighY,
                class: "timelineConnBlip"
            });
            oneSvgLine.append(blip);
        })

        let circle = makeSvg("circle", {
            cx: svgWidth * conn.AvgX,
            cy: midlineY,
            r: circleRadius,
            class: "midlineCircle"
        });
        oneSvgLine.append(circle);

        // addTestBlip(oneSvgLine, 0, blipLowY, blipHighY);
        // addTestBlip(oneSvgLine, svgWidth-1, blipLowY, blipHighY);
    });
}
function addTestBlip(oneSvgLine, blipX, blipLowY, blipHighY) {
    let blip = makeSvg("line", {
        x1: blipX, y1: blipLowY,
        x2: blipX, y2: blipHighY,
        class: "timelineConnTestBlip"
    });
    oneSvgLine.append(blip);
}
function yearLabelsAndSpace(ticksWidth, firstYear, lastYear) {
    let result;

    let everyOtherYear = everyXthYearLabelsMap(
        firstYear, lastYear, 2);
    let candidateYears = Object.keys(everyOtherYear);
    let spacer = gTimelineTab.yearWidth / 2;
    let footprint = (candidateYears.length * (gTimelineTab.yearWidth + spacer)) - spacer;

    if (footprint < ticksWidth) {
        result = everyOtherYear;

    }
    else {
        let everyThirdYear = everyXthYearLabelsMap(
            firstYear, lastYear, 3,
            (y) => String(y).replace(/^../, "'"));

        candidateYears = Object.keys(everyThirdYear);
        result = everyThirdYear;
        let spacer = gTimelineTab.shortYearWidth / 2;
        footprint = (candidateYears.length * (gTimelineTab.shortYearWidth + spacer)) - spacer;
        if (footprint >= ticksWidth) {
            alert(`Too many years for detailed years in graph display!`)
        }
    }
    return result;
}
function everyXthYearLabelsMap(first, last, skipNum, abbrevFn) {
    if (!abbrevFn) {
        abbrevFn = (y) => y;
    }
    let labelYears = {};
    let rawYears = [];
    let latestAddition;

    for (let i=first; i<=last; i+=skipNum) {
        rawYears.push(i);
        labelYears[i] = abbrevFn(i);
        latestAddition = i;
    }
    if ( ! rawYears.includes(last)) {
        labelYears[last] = abbrevFn(last);
        labelYears[latestAddition] = "";
    }
    return labelYears;
}

