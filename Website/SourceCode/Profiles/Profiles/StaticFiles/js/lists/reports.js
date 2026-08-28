gLists.reports = {
    setup: async () => {
        await getPeopleListInfo();

        console.log('reports');
        gLists.currentTab = 'reports';

        if (!gLists.reports.summaryType) {
            gLists.reports.summaryType = 'Institution';
        }

        if (!gLists.reports.listeners) {
            $('.typeSubTab').on('click', function (e) {
                let target = $(e.target);
                gLists.reports.summaryType = target.attr('summaryType');
                gLists.reports.setup();
            })
            gLists.reports.listeners = true;
        }

        let summaryType = gLists.reports.summaryType; // nickname
        if (!gLists.bakedPies) {
            gLists.bakedPies = {};
        }

        parseReportsTabData(gLists.people, summaryType);
    }
};

async function parseReportsTabData(people, summaryType) {
    let target = $('#reportsContent');
    if (people.length == 0) {
        noPeopleOnList(target);
    }
    else {
        if (!gLists.bakedPies[summaryType]) {
            let url = `${g.profilesRootURL}/Lists/Default.aspx/Reports?summaryType=${summaryType}`;

            console.log('reports URL:', url);
            $('.modalupdate').show();
            await jQuery.getJSON(url, function (jsData) {
                console.log('reports data:', jsData);
                gLists.bakedPies[summaryType] = jsData;
            })
            .fail(xhrFail);
            $('.modalupdate').hide();
        }
        if (gLists.bakedPies[summaryType]) {
            google.charts.load('current', {'packages': ['corechart']});
            google.charts.setOnLoadCallback(function () {
                // reports data assumed to be moduleFoo[0]
                reportsParse(gLists.bakedPies[summaryType], summaryType);
            });
        }
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

    let subTab = $(`#s${summaryType}`);
    $('.typeSubTab').removeClass('currentSummarySubTab');
    $('.typeSubTab').addClass('link-ish');
    subTab.removeClass('link-ish');
    subTab.addClass('currentSummarySubTab')

    $('#pieChartWide').addClass(gCommon.hideXsSmallShowOthers);
    // Instantiate and draw our WIDE chart, passing in some options.
    let chartWide = new google.visualization.PieChart(document.getElementById("pieChartWide"));
    chartWide.draw(dataTable, {
        width: 680,
        height: 300,
        fontSize: 12,
        colors: colors,
        legend: { alignment: 'center' },
        chartArea: { left: 20, top: 20, width: '90%', height: '90%' },
        tooltip: { text: 'percentage' }
    });

    // Instantiate and draw our NARROW chart, passing in some options.
    $('#pieChartNarrow').addClass(gCommon.showXsSmallHideOthers);
    let chartNarrow = new google.visualization.PieChart(document.getElementById("pieChartNarrow"));
    chartNarrow.draw(dataTable, {
        width: 350,
        height: 500,
        fontSize: 12,
        colors: colors,
        legend: { position: 'bottom' },
        chartArea: { left: 20, top: 20, width: '90%', height: '90%' },
        tooltip: { text: 'percentage' }
    });

    populateDataRows(jsonData.rows, summaryType, true);
    populateDataRows(jsonData.rows, summaryType, false);
}
function populateDataRows(dataRows, summaryType, wideVsNarrow) {
    let widthFlavor = wideVsNarrow ? 'Wide' : 'Narrow';
    let target = $(`#pieChart${widthFlavor}`);
    let rowId = `pieTable${widthFlavor}`;

    let headerColSpecs = wideVsNarrow ?
            [
                newColumnSpec(`${gCommon.cols8or12} alignMiddle bordE d-flex justify-content-center`,
                    summaryType),
                newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center`,
                    'People'),
                newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center`,
                    'Percent')
            ] :
            [
                newColumnSpec(`${gCommon.cols12} alignMiddle bordE d-flex justify-content-center`,
                    `People per ${summaryType}`)
            ]
    makeRowWithColumns(target, rowId, headerColSpecs, "borderOneSolid mt-3");

    for (let i=0; i<dataRows.length; i++) {
        let dataRow = dataRows[i];
        let [name, count] = [dataRow.c[0].v, dataRow.c[1].v];
        let percentVal = toPercent(Number(count) / gLists.people.length);
        let combinedValue = `${count} ${count==1 ? 'person' : 'people'} (${percentVal}%)`;
        let rowColSpecs = wideVsNarrow ?
            [
                newColumnSpec(`${gCommon.cols8or12} alignMiddle bordE`,
                    name),
                newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center`,
                    count),
                newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center`,
                    toPercent(Number(count) / gLists.people.length))
            ] :
            [
                newColumnSpec(`${gCommon.cols6or12} alignMiddle bordE bold`, name),
                newColumnSpec(`${gCommon.cols6or12} alignMiddle bordE`, combinedValue),
            ];

        makeRowWithColumns(target, rowId+i, rowColSpecs, "borderOneSolid");
    }
}
function toPercent(floatValue) {
    let percentString = (floatValue * 100).toFixed(2) + '%';
    return percentString;
}