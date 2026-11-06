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

        let options = {
            target: target,
            tableId: 'savedListsTable',
            isSavedListsTab: true
        }
        await setupSavedListsTable(options);

        let currPeopleDivTable = $('<div id="currPeopleTitle" class="ps-0 ms-0">My Current List</div>');
        target.append(currPeopleDivTable);

        parsePersonListData(gLists.people, currPeopleDivTable);

        $('#saveButton').on('click', saveCurrentList);

        $('.modalupdate').hide();

        $('#saveName').trigger('focus');
        $('.rtnBtn').click();
    }
};

async function setupSavedListsTable(options) {
    let target          = options.target         ;
    let tableId         = options.tableId        ;
    let isSavedListsTab = options.isSavedListsTab;
    let labelForRefresh = options.labelForRefresh;
    let getLists        = options.getLists;

    let url = `${g.profilesRootURL}/Lists/Default.aspx/SavedLists`;
    await $.get(url, function(result) {
        gLists.savedLists.table = JSON.parse(result);
        console.log('Saved Lists: ', gLists.savedLists.table);
    });
    let mapDisplay = $('<div id="mapDisplay"></div>');
    target.prepend(mapDisplay);
    let preDiv = $('<div></div>');
    target.prepend(preDiv);

    let innerOptions = {
        target:             mapDisplay         ,
        tableId:            tableId        ,
        isSavedListsTab:    isSavedListsTab,
        labelForRefresh:    labelForRefresh,
        getLists:           getLists
    }
    parseSavedListData(innerOptions);
}
function parseSavedListData(options) {
    let target          = options.target         ;
    let tableId         = options.tableId        ;
    let isSavedListsTab = options.isSavedListsTab;
    let labelForRefresh = options.labelForRefresh;
    let getLists        = options.getLists;

    let saves = gLists.savedLists.table;
    let numSaves = saves.length;
    if (numSaves) {
        if (isSavedListsTab) {
            emitSavedListQuasiButtons(target);
        }
        let headerClass = isSavedListsTab ? '' : 'mt-2';

        target.append($(`<div class="fw-bold ${headerClass}">My Saved and Current Person Lists</div>`));

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
            tableId,
            'My Saved Lists',
            colSpecsRowishHeader,
            colSpecsRowishBody,
            'bord9 w-100 ');
        savedListRowish.emitHeader('listsTableHeader');

        if (labelForRefresh) {
            addCurrentListToRowish(savedListRowish, gLists.people.length);
        }

        for (let i = 0; i < saves.length; i++) {
            let s = saves[i];

            let selectCheckbox = $(`<input type="checkbox" lid="${s.ListID}" class="selectCheck_${tableId}"/>`);
            selectCheckbox.attr('aria-label', `Select ${s.ListName}`);
            let extra = gCommon.debug ? ` (${s.ListID})` : '';
            let vals = [`${s.ListName}${extra}`,
                    s.Size,
                    s.CreateDate,
                    s.UpdatedDate,
                    selectCheckbox];

            savedListRowish.emitRow(i, vals, 'highlightHover');
        }

        function getCheckedLids() {
            let checkedIds = $(`.selectCheck_${tableId}`).filter(":checked").map(function() {
                return $(this).attr('lid');
            }).get();
            return checkedIds;
        }
        if (labelForRefresh) {
            let refresh = $(`<button id="redoSavedMap">${labelForRefresh}</button></div>`);
            target.append(refresh);
            refresh.on('click', async () => {
                let lids = getCheckedLids();
                await getLists(lids);
            })

            $(`.selectCheck_${tableId}`).on('change', () => {
                let checkedIds = getCheckedLids();
                console.log('current lids: ', checkedIds);
                let repopulateButton = $('#redoSavedMap')
                if (checkedIds.length > 0) {
                    repopulateButton.removeAttr('disabled').attr('aria-disabled', 'false');
                }
                else {
                    repopulateButton.attr('disabled', 'disabled').attr('aria-disabled', 'true');
                }
            });
        }

        target.append($('<hr/>'));
    }
}
function addCurrentListToRowish(rowishTable, listSize) {
    let listName = `<my current Person list>`;
    let tableId = rowishTable.id;
    let selectCheckbox = $(`<input type="checkbox" checked="checked" lid="0" class="selectCheck_${tableId}"/>`);
    selectCheckbox.attr('aria-label', `Select ${listName}`);
    let vals = [listName,
        listSize,
        '',
        '',
        selectCheckbox];

    rowishTable.emitRow('current', vals, 'highlightHover');
}