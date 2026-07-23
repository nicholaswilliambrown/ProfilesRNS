gLists.reports = {
    setup: () => {
        console.log('reports');
        if (!gLists.reports.done) {
            parseReportsTabData(gLists.manage.people);
            gLists.reports.done = true;
        }
    }
};

function parseReportsTabData(people) {
    let target = $('#reportsContent');
    if (people.length == 0) {
        noPeopleOnList(target);
    }
    else {
        let summaryType = 'Institution';
        let url = `${g.profilesRootURL}/Lists/Default.aspx/Reports?summaryType=${summaryType}`;

        console.log('reports URL:', url);
        jQuery.getJSON(url, function (jsData) {
            console.log('reports data:', jsData);
            gLists.reports.data = jsData;

            google.charts.load('current', {'packages':['corechart']});
            google.charts.setOnLoadCallback(function() {
                // reports data assumed to be moduleFoo[0]
                reportsParse(gLists.reports.data, summaryType);
            });
        })
        .fail(xhrFail);
    }
}

function populateDataTable(dataTable, json) {
    let colData = json.cols;
    for (let i=0; i<colData.length; i++) {
        let data = colData[i];
        dataTable.addColumn(data.type, data.label);
    }

    let rows = [];
    let rowData = json.rows;
    for (let i=0; i<rowData.length; i++) {
        let data = rowData[i];
        let newRow = [data.c[0].v, data.c[1].v];
        rows.push(newRow);
    }
    dataTable.addRows(rows);
}
function reportsParse(jsonData, summaryType) {
    let dataTable = new google.visualization.DataTable();
    populateDataTable(dataTable, jsonData);
    let colors = jsonData.colors.replace(/[\[\]]/g, "").split(',');

    // $('#a-' + summaryType).css('cursor', 'default');
    // $('#a-' + summaryType).css('text-decoration', 'none');
    // $('#a-' + summaryType).css('font-weight', 'bold');
    // $('#a-' + summaryType).css('color', '#000000');

    // Instantiate and draw our chart, passing in some options.
    let chart = new google.visualization.PieChart(document.getElementById("pieChart"));
    chart.draw(dataTable, {
        width: 680,
        height: 300,
        fontSize: 12,
        colors: colors,
        legend: { alignment: 'center' },
        chartArea: { left: 20, top: 20, width: '90%', height: '90%' },
        tooltip: { text: 'percentage' }
    });

    populateDataRows(jsonData.rows, summaryType);
}
function populateDataRows(dataRows, summaryType) {
    let headerColSpecs = [
        newColumnSpec(`${gCommon.cols8or12} alignMiddle bordE d-flex justify-content-center`,
            summaryType),
        newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center`,
            'People'),
        newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center`,
            'Percent'),
    ];

    let target = $('#pieChart');
    let rowId = `pieTable`;
    makeRowWithColumns(target, rowId, headerColSpecs, "borderOneSolid mt-3");

    let numRows
    for (let i=0; i<dataRows.length; i++) {
        let dataRow = dataRows[i];
        let [name, count] = [dataRow.c[0].v, dataRow.c[1].v];

        let rowColSpecs = [
            newColumnSpec(`${gCommon.cols8or12} alignMiddle bordE`,
                name),
            newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center`,
                count),
            newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center`,
                toPercent(Number(count) / gLists.manage.people.length)),
        ];
        makeRowWithColumns(target, rowId+i, rowColSpecs, "borderOneSolid");
    }
}
function toPercent(floatValue) {
    let percentString = (floatValue * 100).toFixed(2) + '%';
    return percentString;
}