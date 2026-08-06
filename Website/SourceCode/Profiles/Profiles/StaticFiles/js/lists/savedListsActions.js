
function saveCurrentList() {
    let name = $('#saveName').val();
    let url = `${g.profilesRootURL}/Lists/Default.aspx/Save?name=${name}`;
    $.get(url, function() {
        console.log('List: ', name, ' saved');
        refreshToCurrentTab();
    })
}

function emitSavedListQuasiButtons(target) {
    let colSpecs = [
        newColumnSpec(`${gCommon.cols7} bold p-1`, 'Modify one or more saved lists'),
        newColumnSpec(`${gCommon.cols5} bold p-1`, 'Modify your current person list')
    ];

    // header row
    makeRowWithColumns(target, 'saveActionsHeader', colSpecs, 'mt-1 myMs-0');

    let actionId = 'saveActions';
    let actionsRow = makeRowWithColumns(target, actionId, colSpecs, "myMs-0");
    let actionsLhs = actionsRow.find(`#${actionId}Col0`);
    let actionsRhs = actionsRow.find(`#${actionId}Col1`);

    populateActionsLhs(actionsLhs);
    populateActionsRhs(actionsRhs);

    target.append($('<hr/>'))
}
function actionHelper(side, id, text, onClick) {
    let actionDiv = $(`<div id ="${id}"></div>`);
    actionDiv.append($(`<img class="pb-1" src="${g.profilesRootURL}/StaticFiles/img/search/icon_squareArrow.gif" 
                                    alt='Right Arrow'/>`));
    actionDiv.append($(`<span class="ms-1 link-ish">${text}</span>`));
    actionDiv.on('click', onClick);

    side.append(actionDiv);
}
function requireSelection() {
    let selected = $(`.listSelectlCheck:checked`);
    if (selected.length == 0) {
        alert('Please select a list from the table.')
    }
    return selected;
}
function populateActionsRhs(rhs) {
    populateSideHelper(rhs);

    actionHelper(rhs, 'divActionDelete', 'Delete Selected', removeSelectedLists);
}
function populateActionsLhs(lhs) {
    populateSideHelper(lhs);

    actionHelper(lhs, 'divActionReplaceMy', 'Replace my person list with the people in the selected list(s)', actionStub);
}
function actionStub() {

}
function populateSideHelper(side) {
    side.removeClass('bold');
    side.empty();
}

async function removeSelectedLists(e) {
    e.preventDefault();
    let url = `${g.profilesRootURL}/Lists/Default.aspx/DeleteSelectedSaved`
    
    let selectedLids = requireSelection();
    if (selectedLids.length) {
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
}
