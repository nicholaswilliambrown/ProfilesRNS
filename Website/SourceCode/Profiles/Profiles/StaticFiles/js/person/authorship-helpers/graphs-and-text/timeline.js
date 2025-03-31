async function populateTimelineGraph(target, yearArray) {
    // Chart will not load into a dynamic div create by $(), but works with document.createElement... !**&^*&@#!
    // https://stackoverflow.com/questions/45947003/how-can-a-google-chart-be-created-within-a-new-element-ive-just-appended-using
    let newDiv = document.createElement('div');
    target.append(newDiv);
    let arrayData = [];
    let dataLength = yearArray.length;
    for (let i=0; i<dataLength; i++) {
        let year = yearArray[i];
        arrayData.unshift([String(year.y).replace(/^../g, "\'"), year.t]);
        if (i == dataLength - 1) {
            arrayData.unshift(['Year', 'Publications']);
        }
    }
    let data = await google.visualization.arrayToDataTable(arrayData);

    let options = {
        bars: 'vertical',
        vAxis: {format: 'decimal'},
        height: 200,
        colors: ['#80B1D3']
    };

    let chart = await new google.charts.Bar(newDiv);

    await chart.draw(data, google.charts.Bar.convertOptions(options));
}

function populateAuthorTimelineGraph(target) {
    let yearArray = gPerson.timeline;

    populateTimelineGraph(target, yearArray);
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
