
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
    let selectionString = '';

    let selected = $(`.listSelectlCheck:checked`);
    if (selected.length == 0) {
        alert('Please select a list from the table.')
    }
    else {
        let selectedVals = [];
        selected.each(function () {
            let lid = $(this).attr('lid');
            selectedVals.push(lid);
        });
        selectionString = selectedVals.join(',');
    }

    return selectionString;
}
function populateActionsRhs(rhs) {
    populateSideHelper(rhs);

    actionHelper(rhs, 'divActionDelete', 'Delete Selected', removeSelectedLists);
}
function populateActionsLhs(lhs) {
    populateSideHelper(lhs);

    actionHelper(lhs, 'divActionReplaceMy', 'Replace my person list with the people in the selected list(s)',
        (e) => modifyActiveListWrapper(e, 'Replace'));
}
async function modifyActiveListWrapper(e, action) {
    let selectedLids = requireSelection();
    if (selectedLids) {
        e.preventDefault();
        await modifyActiveList(action, selectedLids);
    }
}
async function modifyActiveList(action, listIds) {
    let url = `${g.profilesRootURL}/Lists/Default.aspx/ModifyActiveList`;
    console.log(`Posting ${action} to ${url}`);

    let dataObject = {
        action: action,
        listIds: listIds
    };

    await $.post(url, dataObject)
        .done(function (result) {
            console.log(`Result: ${result}`);
        })
        .fail(xhrFail);

    refreshToCurrentTab();

    // jQuery.ajax({
    //     type: "POST",
    //     url: "<%=Profiles.Framework.Utilities.Root.Domain%>/Lists/Default.aspx/ModifyActiveList",
    //     data: "{action: '" + action + "',listids: '" + listIds + "'}",
    //     contentType: "application/json; charset=utf-8",
    //     dataType: "json",
    //     success: OnSaveSuccess,
    //     failure: function (response) {
    //         $("input:checkbox").prop('checked', false);
    //         // alert(response.d + " " + check_text + " " + obj.checked);
    //         document.location.href = "<%= Profiles.Framework.Utilities.Root.Domain%>/lists/default.aspx?type=saved";
    //     }
    // });
}
function actionStub() {

}
function populateSideHelper(side) {
    side.removeClass('bold');
    side.empty();
}

async function removeSelectedLists(e) {
    let selectedLids = requireSelection();
    if (selectedLids) {
        e.preventDefault();
        let url = `${g.profilesRootURL}/Lists/Default.aspx/DeleteSelectedSaved`;

        console.log(`Want to remove: `, selectedLids);

        let dataObject = {
            lids: selectedLids,
        };

        await $.post(url, dataObject)
            .fail(xhrFail);

        refreshToCurrentTab();
    }
}
