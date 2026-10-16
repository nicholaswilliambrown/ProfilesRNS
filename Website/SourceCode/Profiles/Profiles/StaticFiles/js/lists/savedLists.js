gLists.savedLists = {
    setup: async () => {
        await getPeopleListInfo();

        console.log('savedLists');
        gLists.currentTab = 'savedLists';
        sessionStorage.removeItem(gLists.rememberedTab);

        gLists.visualizeLists = { vizData: [], vizClusterData: []};

        $('.modalupdate').show();

        let target = $('#savedDynamicDisplay');
        target.empty();
        let url = `${g.profilesRootURL}/Lists/Default.aspx/SavedLists`;
        await $.get(url, function(result) {
            gLists.savedLists.data = JSON.parse(result);
            console.log('Saved Lists: ', gLists.savedLists.data);
        });

        parseSavedListData(target);

        let currPeopleDivTable = $('<div id="currPeopleTitle" class="ps-0 ms-0">My Current List</div>');
        target.append(currPeopleDivTable);

        parsePersonListData(gLists.people, currPeopleDivTable);

        $('#saveButton').on('click', saveCurrentList);

        $('.modalupdate').hide();
    }
};
function parseSavedListData(target) {
    let saves = gLists.savedLists.data;
    let numSaves = saves.length;
    if (numSaves) {
        emitSavedListQuasiButtons(target);

        let colSpecsRowishHeader = [
            newColumnSpec(`col-4 bordE py-1 `,   'Person List'),
            newColumnSpec(`col-1 bordE py-1 `,   'People'),
            newColumnSpec(`col-3 bordE py-1 `,   'Created Date'),
            newColumnSpec(`col-3 bordE py-1`,    'Updated Date'),
            newColumnSpec(`col-1 text-center align-middle align-items-center ps-1 pe-0`,    'Select')
        ];
        let colSpecsRowishBody = [
            newColumnSpec(`text-start bordE py-0 `,      ''),
            newColumnSpec(`text-start bordE py-0 `,      ''),
            newColumnSpec(`text-start bordE py-0 `,      ''),
            newColumnSpec(`text-start bordE py-0`,       ''),
            newColumnSpec(`d-flex align-items-center justify-content-md-center py-0`,          '')
        ];
        let savedListRowish = new RowishTable(target,
            'savedListsTable', 'My Current People',
            colSpecsRowishHeader, colSpecsRowishBody,
            'bord9 w-100 ');
        savedListRowish.emitHeader('listsTableHeader');

        for (let i = 0; i < saves.length; i++) {
            let s = saves[i];
            let id = 'savedList' + i;

            let removalCheckbox = $(`<input type="checkbox" lid="${s.ListID}" class="listSelectlCheck"/>`);
            vals = [s.ListName,
                    s.Size,
                    s.CreateDate,
                    s.UpdatedDate,
                    removalCheckbox];

         savedListRowish.emitRow(i, vals, 'bor8 highlightHOver');
        }
        target.append($('<hr/>'));
    }
}
function makeColSpecsSaves(vals) {
    let colSpecs = [newColumnSpec(`${gCommon.cols4} bordE p-1`,             vals[0]),
        newColumnSpec(`${gCommon.cols1} bordE p-1`,                         vals[1]),
        newColumnSpec(`${gCommon.cols3} bordE p-1`,                         vals[2]),
        newColumnSpec(`${gCommon.cols3} bordE p-1`,                         vals[3]),
        newColumnSpec(`${gCommon.cols1} p-1 d-flex justify-content-center`, vals[4])
    ];
    return colSpecs;
}
