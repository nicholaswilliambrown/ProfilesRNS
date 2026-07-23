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
        let summaryType = 'institution';
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

    $('#a-' + summaryType).css('cursor', 'default');
    $('#a-' + summaryType).css('text-decoration', 'none');
    $('#a-' + summaryType).css('font-weight', 'bold');
    $('#a-' + summaryType).css('color', '#000000');
    colorArray = ['#4E79A7', '#F28E2B', '#E15759', '#76B7B2', '#59A14F', '#EDC948', '#B07AA1', '#FF9DA7', '#9C755F', '#BAB0AC'];
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
}
