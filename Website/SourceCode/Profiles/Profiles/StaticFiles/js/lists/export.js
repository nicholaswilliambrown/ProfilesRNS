gLists.export = {
    setup: async () => {
        await getPeopleListInfo();

        console.log('setting up for export!');
        gLists.currentTab = 'export';

        gLists.export.urlInitial = `${g.profilesRootURL}/Lists/Default.aspx/Export/`;
        exportData(gLists.people);
    }
};

function exportData(people) {
    let target = $('#exportContent');
    if (people.length == 0) {
        noPeopleOnList(target);
    } else {
        let exportTable = $('#exportTable');
        exportTable.empty();
        let wideTable = $(`<div id="exportTableWide" class="${gCommon.hideXsSmallShowOthers}"></div>`);
        let narrowTable = $(`<div id="exportTableNarrow" class="${gCommon.showXsSmallHideOthers}"></div>`);
        exportTable.append(wideTable);
        exportTable.append(narrowTable);

        let blurbs = {};
        blurbs.People = 'One row per person. Columns include name, address, institution, department, faculty rank, and number of publications.';
        blurbs.Publications = 'One row per person-publication pair. Columns include the publication title, date, and PubMed ID if available.';
        blurbs.Connections = 'This file lists pairs of people who are co-authors. Columns include the number of co-authored publications.';

        wideExport(wideTable, blurbs);
        narrowExport(narrowTable, blurbs);
    }
}
function wideExport(target, blurbs) {
    let headerColSpecs = [
        newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center bold`,
            'File'),
        newColumnSpec(`${gCommon.cols10or12} alignMiddle bordE d-flex justify-content-center bold`,
            'Description'),
    ];

    let rowId = `exportTableWide`;
    makeRowWithColumns(target, rowId, headerColSpecs, `borderOneSolid mt-3`);

    for (let flavor of ['People', 'Publications', 'Connections']) {
        let blurb = `Download ${flavor} data as CSV`;
        let flavorButton = $(`<button type="button" title="${blurb}" flavor="${flavor}" class="link-ish" aria-label="${blurb}">${flavor}</button>`);
        flavorButton.on('click', function() {
            $('.modalupdate').show();
            flavoredExport(flavor);
            $('.modalupdate').hide();
        });

        let rowColSpecs = [
            newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE`,
                flavorButton),
            newColumnSpec(`${gCommon.cols10or12} alignMiddle bordE`,
                blurbs[flavor]),
        ];
        makeRowWithColumns(target, rowId + '-' + flavor, rowColSpecs, `borderOneSolid`);
    }
}

function narrowExport(target, blurbs) {
    let headerColSpecs = [
        newColumnSpec(`${gCommon.cols12} alignMiddle bordE d-flex justify-content-center bold`,
            'Files and Descriptions')];
    let rowId = `exportTableNarrow`;
    makeRowWithColumns(target, rowId, headerColSpecs, `borderOneSolid mt-3`);

    for (let flavor of ['People', 'Publications', 'Connections']) {
        let flavorButton = $(`<button type="button" flavor="${flavor}" class="link-ish bold">${flavor}:</button>`);
        flavorButton.on('click', function() {
            $('.modalupdate').show();
            flavoredExport(flavor);
            $('.modalupdate').hide();
        });

        let valueDiv = $('<div></div>');
        valueDiv.append(flavorButton).append(` ${blurbs[flavor]}`);
        let rowColSpecs = [newColumnSpec(`${gCommon.cols12} alignMiddle bordE`, valueDiv)];
        makeRowWithColumns(target, rowId + '-' + flavor, rowColSpecs, `borderOneSolid`);
    }
}

function flavoredExport(flavor) {
    // needs to be a location.href, vs an ajax call, in order to trigger d/l
    let url = gLists.export.urlInitial + flavor;
    window.location.href = url;
}
