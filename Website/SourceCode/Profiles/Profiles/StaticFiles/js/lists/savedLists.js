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

        await setupSavedListsTable(target, 'savedListsTable', true);

        let currPeopleDivTable = $('<div id="currPeopleTitle" class="ps-0 ms-0">My Current List</div>');
        target.append(currPeopleDivTable);

        parsePersonListData(gLists.people, currPeopleDivTable);

        $('#saveButton').on('click', saveCurrentList);

        $('.modalupdate').hide();

        $('#saveName').trigger('focus');
        $('.rtnBtn').click();
    }
};

// pass in an array of ids
async function getSavedListsForMapAndCluster(listIds) {
    let url = `${g.profilesRootURL}/Lists/Default.aspx/SavedListsMap`;
    let commaListIds = listIds.join(',');

    await $.post(url, {listIds: commaListIds}, function(result) {
        gLists.savedLists.map = JSON.parse(result);
        console.log('Saved Lists: ', gLists.savedLists.map);
    });

    // url = `${g.profilesRootURL}/Lists/Default.aspx/SavedListsCluster`;
    // await $.get(url, function(result) {
    //     gLists.savedLists.cluster = JSON.parse(result);
    //     console.log('Saved Lists: ', gLists.savedLists.cluster);
    // });

}
async function setupSavedListsTable(target, tableId, isSavedListsTab) {
    let url = `${g.profilesRootURL}/Lists/Default.aspx/SavedLists`;
    await $.get(url, function(result) {
        gLists.savedLists.table = JSON.parse(result);
        console.log('Saved Lists: ', gLists.savedLists.table);
    });
    let preDiv = $('<div></div>');
    target.prepend(preDiv)
    parseSavedListData(preDiv, tableId, isSavedListsTab);
}
function parseSavedListData(target, tableId, isSavedListsTab) {
    let saves = gLists.savedLists.table;
    let numSaves = saves.length;
    if (numSaves) {
        if (isSavedListsTab) {
            emitSavedListQuasiButtons(target);
        }
        let headerClass = isSavedListsTab ? '' : 'mt-2';

        target.append($(`<div class="fw-bold ${headerClass}">My Saved Person Lists</div>`));

        let colSpecsRowishHeader = [
            newColumnSpec(`col-4 bordE py-1 `,   'Person List'),
            newColumnSpec(`col-1 bordE py-1 `,   'People'),
            newColumnSpec(`col-3 bordE py-1 `,   'Created Date'),
            newColumnSpec(`col-3 bordE py-1`,    'Updated Date'),
            newColumnSpec(`col-1 text-center align-middle ps-1 pe-0`,    'Select')
        ];
        let colSpecsRowishBody = [
            newColumnSpec(`text-start bordE py-0 `,      ''),
            newColumnSpec(`text-start bordE py-0 `,      ''),
            newColumnSpec(`text-start bordE py-0 `,      ''),
            newColumnSpec(`text-start bordE py-0`,       ''),
            newColumnSpec(`d-flex align-items-center justify-content-md-center py-0`,          '')
        ];
        let savedListRowish = new RowishTable(target,
            tableId, 'My Saved Lists',
            colSpecsRowishHeader, colSpecsRowishBody,
            'bord9 w-100 ');
        savedListRowish.emitHeader('listsTableHeader');

        for (let i = 0; i < saves.length; i++) {
            let s = saves[i];

            let selectCheckbox = $(`<input type="checkbox" lid="${s.ListID}" class="listSelectlCheck"/>`);
            selectCheckbox.attr('aria-label', `Select ${s.ListName}`);
            let vals = [`${s.ListName} (${s.ListID})`,
                    s.Size,
                    s.CreateDate,
                    s.UpdatedDate,
                    selectCheckbox];

            savedListRowish.emitRow(i, vals, 'highlightHover');
        }
        target.append($('<hr/>'));
    }
}
