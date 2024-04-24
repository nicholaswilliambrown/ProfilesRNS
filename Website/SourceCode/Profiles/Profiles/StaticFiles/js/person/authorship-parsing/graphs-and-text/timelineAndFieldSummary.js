async function authNavGreenField(e, options) {
    let overallDivId = options.overallDivId;
    let toTextId     = options.toTextId    ;
    let toGraphId    = options.toGraphId   ;
    let theText      = options.theText        ;
    let graphId      = options.graphId     ;
    let graphFn      = options.graphFn     ;
    let addTextFn    = options.addTextFn   ;

    authNavAdjustStyle(e);
    gPerson.authorshipInnerDiv.empty();

    let overallDiv = $(`<div id="${overallDivId}"></div>`);
    gPerson.authorshipInnerDiv.append(overallDiv);

    let aClickToText = $('<a class="link-ish toggleGraphLink mb-2" id="${toTextId}">click here</a>');
    let aClickToGraph = $('<a class="link-ish toggleGraphLink mb-2" id="${toGraphId}">click here</a>');

    let mainText = theText;
    let overallDivToTextDiv = $(`<div class="mt-2">${mainText} To see the data as text, </div>`);
    let overallDivToGraphDiv = $(`<div class="mt-2">${mainText} To return to the graph, </div>`);

    overallDivToTextDiv.append(aClickToText).append($('<span class="mb-4">.</span>'));
    overallDivToGraphDiv.append(aClickToGraph).append($('<span class="mb-4">.</span>'));

    let graphDiv = $(`<div class="forGraph mt-3 ${graphId}" id="${graphId}"></div>`);
    overallDivToTextDiv.append(graphDiv);
    overallDivToTextDiv.append($(`<div id="${graphId}-alt"></div>`));

    addTextFn(overallDivToGraphDiv);

    overallDiv.append(overallDivToTextDiv);
    overallDiv.append(overallDivToGraphDiv);

    overallDivToGraphDiv.hide();

    aClickToText.on('click', async function() {
        overallDivToTextDiv.hide();
        overallDivToGraphDiv.show();

    });
    aClickToGraph.on('click', function() {
        overallDivToGraphDiv.hide();
        overallDivToTextDiv.show();
    });

    overallDivToGraphDiv.hide();

    graphFn(graphDiv);
}
function authNavTimeline(e) {
    authNavGreenField(e, {
        "overallDivId": "authTimelineDiv",
        "toTextId":     "toTimelineText",
        "toGraphId":    "toTimelineGraph",
        "theText":      "This graph shows the total number of publications by year. ",
        "graphId":      "timelineGraphDiv",
        "graphFn":      populateTimelineGraph,
        "addTextFn":    authAddTextForTimeline
    });
}
function authNavFieldSummary(e) {
    authNavGreenField(e, {
        "overallDivId": "authFieldSummaryDiv",
        "toTextId":     "toFieldSummaryText",
        "toGraphId":    "toFieldSummaryGraph",
        "theText":      `This graph shows the number and percent of publications by field. Fields are based on how the National Library of Medicine (NLM) classifies the publications' journals and might not represent the specific topics of the publications. Note that an individual publication can be assigned to more than one field. As a result, the publication counts in this graph might add up to more than the number of publications the person has written. `,
        "graphId":      "fieldSummaryGraphDiv",
        "graphFn":      populateFieldSummaryGraph,
        "addTextFn":    authAddTextForFieldSummary
    });
}
function fieldSummaryDataForChart() {
    let data = new google.visualization.DataTable();

    data.addColumn('string', 'BroadJournalHeading');
    data.addColumn('number', 'Count');

    let inputArray = gPerson.fieldSummary;

    let rows = [];
    let colors = [];

    for (let i=0; i<inputArray.length; i++) {
        let fieldData = inputArray[i];
        rows.unshift([fieldData.BroadJournalHeading, fieldData.Count]);
        colors.unshift(fieldData.Color);
    }
    data.addRows(rows);

    return { data: data, "colors": colors };
}
function populateFieldSummaryGraph(graphDiv) {
    let chartInfo = fieldSummaryDataForChart();

    let colors = chartInfo.colors;
    let data = chartInfo.data;

    // Chart will not load into a dynamic div create by $(), but works with document.createElement... !**&^*&@#!
    // https://stackoverflow.com/questions/45947003/how-can-a-google-chart-be-created-within-a-new-element-ive-just-appended-using
    let newDiv = document.createElement('div');
    graphDiv.append(newDiv);
    let chart = new google.visualization.PieChart(newDiv);
    chart.draw(data, {
        width: 680,
        height: 300,
        fontSize: 12,
        colors: colors,
        legend: {alignment: 'center'},
        chartArea: {left: 20, top: 20, width: '90%', height: '90%'},
        tooltip: {text: 'percentage'}
    });
}

function populateTimelineGraph(graphDiv) {
    // Chart will not load into a dynamic div create by $(), but works with document.createElement... !**&^*&@#!
    // https://stackoverflow.com/questions/45947003/how-can-a-google-chart-be-created-within-a-new-element-ive-just-appended-using
    let newDiv = document.createElement('div');
    graphDiv.append(newDiv);

    let yearArray = gPerson.timeline;
    let arrayData = [];
    let dataLength = yearArray.length;
    for (let i=0; i<dataLength; i++) {
        let year = yearArray[i];
        arrayData.unshift([String(year.y).replace(/^../g, "\'"), year.t]);
        if (i == dataLength - 1) {
            arrayData.unshift(['Year', 'Publications']);
        }
    }
    let data = google.visualization.arrayToDataTable(arrayData);

    let options = {
        bars: 'vertical',
        vAxis: {format: 'decimal'},
        height: 200,
        colors: ['#80B1D3']
    };

    let chart = new google.charts.Bar(newDiv);

    chart.draw(data, google.charts.Bar.convertOptions(options));
}
function authAddTextForTimeline(target) {
    let authorshipJson = gPerson.authorshipJson;
    let timelineArray = authorshipJson.Timeline;

    for (let i=0; i<timelineArray.length; i++) {
        if (i == 0) {
            let row = addTimelineTextRow(target, "Year", "Publications");
            row.addClass("bold");
        }
        let timelineData = timelineArray[i];
        addTimelineTextRow(target, timelineData.y, timelineData.t);
    }
}
function authAddTextForFieldSummary(target) {
    let authorshipJson = gPerson.authorshipJson;
    let fieldSummaryArray = authorshipJson.FieldSummary;

    for (let i=0; i<fieldSummaryArray.length; i++) {
        if (i == 0) {
            let row = addFieldSummaryTextRow(target, "Field", "Publications", "Weight");
            row.addClass("bold");
        }
        let fieldSummaryData = fieldSummaryArray[i];
        addFieldSummaryTextRow(target,
            fieldSummaryData.BroadJournalHeading,
            fieldSummaryData.Count,
            fieldSummaryData.Weight);
    }
}
function addTimelineTextRow(target, left, right) {
    let tlRow = $(`<div" class="row timeline-row"></div>`);
    target.append(tlRow);

    let tlLeft = $(`<div class="border border-secondary ${gCommon.cols6} d-flex justify-content-center"></div>`);
    let tlRight = $(`<div class="border border-secondary ${gCommon.cols6} d-flex justify-content-center"></div>`);

    tlRow.append(tlLeft).append(tlRight);

    tlLeft.html(left);
    tlRight.html(right);

    return tlRow;
}
function addFieldSummaryTextRow(target, left, mid, right) {
    let fsRow = $(`<div" class="ms-1 row field-summary-row"></div>`);
    target.append(fsRow);

    let fsLeft = $(`<div class="border border-secondary ${gCommon.cols4} d-flex justify-content-center"></div>`);
    let fsMid = $(`<div class="border border-secondary ${gCommon.cols4} d-flex justify-content-center"></div>`);
    let fsRight = $(`<div class="border border-secondary ${gCommon.cols4} d-flex justify-content-center"></div>`);

    fsRow.append(fsLeft).append(fsMid).append(fsRight);

    fsLeft.html(left);
    fsMid.html(mid);
    fsRight.html(right);

    return fsRow;
}
