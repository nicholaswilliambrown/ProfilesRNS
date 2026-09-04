
function saveCurrentList() {
    let name = $('#saveName').val();
    let url = `${g.profilesRootURL}/Lists/Default.aspx/Save?name=${name}`;
    $.get(url, function() {
        console.log('List: ', name, ' saved');
        refreshButComeBackToSaved();
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
function requireSelection(onlyOne) {
    let selectionString = '';

    let selected = $(`.listSelectlCheck:checked`);
    if (selected.length == 0) {
        alert('Please select a list from the table.')
    }
    else if (selected.length > 1 && onlyOne) {
        alert('Please select only one item from table for rename action.')
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
function activateVisualizeTab() {
    let selectedLids = requireSelection();
    if (selectedLids) {
        adjustToTab($('#visualizeLists'));
        populateInitialVisualizeContent();
    }
}
async function populateInitialVisualizeContent() {
    let target = $('#visualizeListsContent');
    target.empty();

    await backendActionWrapper(null, 'VisualizeLists', '');
    console.log("=============== Viz Data: ", gLists.resultData);

    gLists.visualizeLists.vizData = JSON.parse(gLists.resultData);

    await loadClusterHtml(target);
    setupHtml(target);
}
async function createListCluster(listCodes) {
    await backendAction('', listCodes, "VisualizeListsCluster", '');
    let result = JSON.parse(gLists.resultData);
    console.log("=============== Viz Cluster Data: ", result);
    return result;
}
function harvestNameAndApplyToList() {
    let selectedLid = requireSelection(true);
    if (selectedLid) {
        $('#nameOverlay').show();
        $('#newListName').val('');
        $('#saveNewListName').off('click').on('click', (e) => {
            let name = $('#newListName').val();
            if (name) {
                backendAction('Rename', selectedLid, 'AddUpdateList', name);
            }
            $('#nameOverlay').hide();
        });
    }
}
function populateActionsLhs(lhs) {
    populateSideHelper(lhs);
    let restApi = 'ModifyActiveList';

    actionHelper(lhs, 'divActionReplace',
    'Replace my person list with the people in the selected list(s)',
        (e) => backendActionWrapper(e, restApi, 'Replace'));
    actionHelper(lhs, 'divActionAdd',
    'Add the people in the selected list(s) to my person list',
        (e) => backendActionWrapper(e, restApi, 'Add'));
    actionHelper(lhs, 'divActionRemove',
    'Remove the people in the selected list(s) from my person list',
        (e) => backendActionWrapper(e, restApi, 'Remove'));
    actionHelper(lhs, 'divActionRemoveNotInAll',
    'Remove the people who are not in all of the selected list(s) from my person list',
        (e) => backendActionWrapper(e, restApi, 'RemoveNotInAll'));
    actionHelper(lhs, 'divActionRemoveNotInAny',
    'Remove the people who are not in at least one of the selected list(s) from my person list',
        (e) => backendActionWrapper(e, restApi, 'RemoveNotInAny'));
}
function populateActionsRhs(rhs) {
    populateSideHelper(rhs);
    let restApi = 'AddUpdateList';

    actionHelper(rhs, 'divActionReplace',
        'Replace the selected list with the people in my person list',
        (e) => backendActionWrapper(e, restApi, 'Replace'));
    actionHelper(rhs, 'divActionRename',
        'Rename the selected list',
        harvestNameAndApplyToList);
    actionHelper(rhs, 'divActionDelete',
        'Delete the selected list(s)',
        (e) => backendActionWrapper(e, restApi, 'Delete'));

    rhs.append('<div class="mt-3"></div>');

    actionHelper(rhs, 'divActionVisualize',
        'Create a cluster view of the selected list(s)',
        activateVisualizeTab);
}

async function backendActionWrapper(e, restApi, mutationAction, oneListOnly, name) {
    if (e) { e.preventDefault(); }

    let selectedLids = requireSelection();
    if (selectedLids) {
        if (!name) name = '';
        await backendAction(mutationAction, selectedLids, restApi, name);
    }
}
async function backendAction(mutationAction, listIds, restApi, name) {
    if (!name) name = '';

    let url = `${g.profilesRootURL}/Lists/Default.aspx/${restApi}`;
    console.log(`Posting ${mutationAction} to ${url}`);

    let dataObject = {
        action: mutationAction,
        listIds: listIds,
        name: name
    };

    let resultData;
    await $.post(url, dataObject)
        .done(function (result) {
            resultData = result;
        })
        .fail(xhrFail);

    if (mutationAction) {
        refreshButComeBackToSaved();
    }
    else {
        gLists.resultData = resultData;
    }
}
function populateSideHelper(side) {
    side.removeClass('bold');
    side.empty();
}
/////////////////////////////////////////////////////////////////
