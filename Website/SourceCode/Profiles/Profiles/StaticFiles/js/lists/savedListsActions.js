
function saveCurrentList() {
    let name = $('#saveName').val();
    let url = `${g.profilesRootURL}/Lists/Default.aspx/Save?name=${name}`;
    $.get(url, function() {
        console.log('List: ', name, ' saved');
        refreshButComeBackToCurrentTab();
    })
}

function emitSavedListQuasiButtons(target) {
    let colSpecs = [
        newColumnSpec(`${gCommon.cols7or12} p-1`, '<div class="ms-1 mb-1 fw-bold">Modify your current person list</div>'),
        newColumnSpec(`${gCommon.cols5or12} p-1`, '<div class="ms-1 mb-1 fw-bold">Modify one or more saved lists</div>')
    ];

    let actionId = 'saveActions';
    let actionsRow = makeRowWithColumns(target, actionId, colSpecs, "");
    let actionsLhs = actionsRow.find(`#${actionId}Col0`);
    let actionsRhs = actionsRow.find(`#${actionId}Col1`);

    populateActionsLhs(actionsLhs);
    populateActionsRhs(actionsRhs);

    target.append($('<hr/>'))
}
function actionHelper(side, id, text, onClick) {
    let actionButton = $(`<button id ="${id}" type="button"
            class="ms-1 link-ish text-start d-flex align-items-start"></button>`);
    // flex-shrink-0 below prevents gif from shrinking
    actionButton.append($(`<img alt=""
            class="pb-1 me-2 flex-shrink-0" src="${g.profilesRootURL}/StaticFiles/img/search/icon_squareArrow.gif"/>`));
    actionButton.append($(`<span>${text}</span>`));
    actionButton.on('click', onClick);

    side.append(actionButton);
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
function harvestNameAndRenameList() {
    let selectedLid = requireSelection(true);
    if (selectedLid) {
        makeModal($('#myModal'),
            'Rename selected Person List as',
            'Enter a (new) name, then click Save List',
            true,
            (name) => {
                if (name) {
                    backendAction('Rename', selectedLid, 'AddUpdateList', name);
                }
            },
            'Save list'
        );
    }
}
function populateActionsLhs(lhs) {
    let restApi = 'ModifyActiveList';

    actionHelper(lhs, 'divActionReplaceMyPeople',
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
    let restApi = 'AddUpdateList';

    actionHelper(rhs, 'divActionReplaceWithMyPeople',
        'Replace the selected list with the people in my person list',
        (e) => backendActionWrapper(e, restApi, 'Replace'));

    actionHelper(rhs, 'divActionRename',
        'Rename the selected list',
        harvestNameAndRenameList);

    actionHelper(rhs, 'divActionDelete',
        'Delete the selected list(s)',
        (e) => backendActionWrapper(e, restApi, 'Delete'));

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
        refreshButComeBackToCurrentTab();
    }
    else {
        gLists.resultData = resultData;
    }
}
/////////////////////////////////////////////////////////////////
