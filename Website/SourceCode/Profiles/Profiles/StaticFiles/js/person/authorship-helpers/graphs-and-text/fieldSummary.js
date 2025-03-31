function fieldSummaryDataForChart() {
    let inputArray = gPerson.fieldSummary;
    if (!inputArray) {
        return; // no data to display
    }

    let data = new google.visualization.DataTable();

    data.addColumn('string', 'BroadJournalHeading');
    data.addColumn('number', 'Count');

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
    if (!chartInfo) {
        return; // no data to display
    }

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

function authAddTextForFieldSummary(target) {
    let authorshipJson = gPerson.authorshipJson;
    let fieldSummaryArray = authorshipJson.FieldSummary;
    if (!fieldSummaryArray) {
        return; // no data to display
    }

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
