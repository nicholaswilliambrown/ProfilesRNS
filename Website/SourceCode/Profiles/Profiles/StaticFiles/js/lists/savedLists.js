gLists.savedLists = {
    setup: async () => {
        console.log('savedLists');
        gLists.currentTab = 'savedLists';

        $('.modalupdate').show();

        if (!gLists.savedLists.done) {
            let target = $('#savedDynamicDisplay');
            target.empty();
            let url = `${g.profilesRootURL}/Lists/Default.aspx/SavedLists`;
            await $.get(url, function(result) {
                gLists.savedLists.data = JSON.parse(result);
                console.log('Saved Lists: ', gLists.savedLists.data);
            });

            emitSavedListQuasiButtons(target);
            parseSavedListData(target);

            target.append($('<hr/>'));

            parsePersonListData(gLists.manage.people, target);

            $('#saveButton').on('click', saveCurrentList);

            gLists.savedLists.done = true;
        }

        $('.modalupdate').hide();
    }
};
function saveCurrentList() {
    let name = $('#saveName').val();
    let url = `${g.profilesRootURL}/Lists/Default.aspx/Save?name=${name}`;
    $.get(url, function() {
        console.log('List: ', name, ' saved');
        refreshToCurrentTab();
    })
}
function emitSavedListQuasiButtons(target) {
    let quasiButtonsDiv = $('<div id="quasiButtonsDiv"></div>');
    let spanDelete = $('<span id ="spanDelete" class="link-ish">Delete Selected</span>');
    spanDelete.on('click', removeSelectedLists);
    quasiButtonsDiv.append(spanDelete);
    target.append(quasiButtonsDiv);
}
function parseSavedListData(target) {
    let saves = gLists.savedLists.data;
    let vals =
        [   'Person List',
            'People',
            'Created Date',
            'Updated Date',
            'Select' ];
    let colSpecs = makeColSpecsSaves(vals);
    makeRowWithColumns(target, 'SavedListsHeader', colSpecs, 'personTableHeader bord9');

    for (let i=0; i<saves.length; i++) {
        let s = saves[i];
        let id = 'savedList' + i;

        let removalCheckbox = $(`<input type="checkbox" lid="${s.ListID}" class="saveRemovalCheck"/>`);

        vals = [    `${s.ListName} (${s.ListID})`,
                    s.Size,
                    s.CreateDate,
                    s.UpdatedDate,
                    removalCheckbox];
        colSpecs = makeColSpecsSaves(vals);
        makeRowWithColumns(target, id, colSpecs, 'personTableHeader bord9');
    }
}
function makeColSpecsSaves(vals) {
    let colSpecs = [newColumnSpec(`${gCommon.cols4} bordE p-1`, vals[0]),
        newColumnSpec(`${gCommon.cols1} bordE p-1`,             vals[1]),
        newColumnSpec(`${gCommon.cols3} bordE p-1`,             vals[2]),
        newColumnSpec(`${gCommon.cols3} bordE p-1`,             vals[3]),
        newColumnSpec(`${gCommon.cols1} p-1`,                   vals[4])
    ];
    return colSpecs;
}
async function removeSelectedLists(e) {
    e.preventDefault();
    let url = `${g.profilesRootURL}/Lists/Default.aspx/DeleteSelectedSaved`
    let selected = $(`.saveRemovalCheck:checked`);
    let selectedLids = [];
    selected.each(function () {
        let lid = $(this).attr('lid');
        selectedLids.push(lid);
    });
    let stringLids = selectedLids.join(',');
    console.log(`Want to remove: `, stringLids);

    let dataObject = {
        lids: stringLids,
    };

    await $.post(url, dataObject)
        .fail(xhrFail);

    refreshToCurrentTab();
}
function refreshToCurrentTab() {
    let refreshUrl = new URL(window.location.href);
    refreshUrl.searchParams.set('tab', gLists.currentTab);

    window.location.href = refreshUrl.toString();
}