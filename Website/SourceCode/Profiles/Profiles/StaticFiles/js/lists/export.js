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
        target = $('#exportTable');
        target.empty();
        let headerColSpecs = [
            newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE d-flex justify-content-center bold`,
                'File'),
            newColumnSpec(`${gCommon.cols10or12} alignMiddle bordE d-flex justify-content-center bold`,
                'Description'),
        ];

        let rowId = `exportTable`;
        makeRowWithColumns(target, rowId, headerColSpecs, "borderOneSolid mt-3");

        let blurbs = {};
        blurbs.People = 'One row per person. Columns include name, address, institution, department, faculty rank, and number of publications.';
        blurbs.Publications = 'One row per person-publication pair. Columns include the publication title, date, and PubMed ID if available.';
        blurbs.Connections = 'This file lists pairs of people who are co-authors. Columns include the number of co-authored publications.';

        for (let flavor of ['People', 'Publications', 'Connections']) {
            let flavorSpan = $(`<span flavor="${flavor}" class="link-ish">${flavor}</span>`);
            flavorSpan.on('click', function() {
                $('.modalupdate').show();
                flavoredExport(flavor);
                $('.modalupdate').hide();
            });

            let rowColSpecs = [
                newColumnSpec(`${gCommon.cols2or12} alignMiddle bordE`,
                    flavorSpan),
                newColumnSpec(`${gCommon.cols10or12} alignMiddle bordE`,
                    blurbs[flavor]),
            ];
            makeRowWithColumns(target, rowId + '-' + flavor, rowColSpecs, "borderOneSolid");
        }
    }
}

function flavoredExport(flavor) {
    // needs to be a location.href, vs an ajax call, in order to trigger d/l
    let url = gLists.export.urlInitial + flavor;
    window.location.href = url;
}
