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

            parseSavedListData(target);

            let personListDiv = $('<div id="personListDiv"></div>');
            target.append(personListDiv);
            parsePersonListData(gLists.manage.people, personListDiv);

            $('#saveButton').on('click', saveCurrentList);

            gLists.savedLists.done = true;
        }

        $('.modalupdate').hide();
    }
};
function parseSavedListData(target) {
    let saves = gLists.savedLists.data;
    let numSaves = saves.length;
    if (numSaves) {
        emitSavedListQuasiButtons(target);
        let vals =
            ['Person List',
                'People',
                'Created Date',
                'Updated Date',
                'Select'];
        let colSpecs = makeColSpecsSaves(vals);
        makeRowWithColumns(target, 'SavedListsHeader', colSpecs, 'listsTableHeader bord9 myMs-0');

        for (let i = 0; i < saves.length; i++) {
            let s = saves[i];
            let id = 'savedList' + i;

            let removalCheckbox = $(`<input type="checkbox" lid="${s.ListID}" class="listSelectlCheck"/>`);

            vals = [s.ListName,
                    s.Size,
                    s.CreateDate,
                    s.UpdatedDate,
                    removalCheckbox];
            colSpecs = makeColSpecsSaves(vals);
            makeRowWithColumns(target, id, colSpecs, 'bord9 highlightHover myMs-0');
        }
        target.append($('<hr/>'));
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
