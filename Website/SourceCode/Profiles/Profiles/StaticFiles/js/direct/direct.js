let fleshyTarget = new Map();
gConcepts.meshShortcuts = [];
gConcepts.pubsShortcuts = [];

async function setupDirectPage() {
    await commonSetup('Search Other Institutions');
    $('#modules-right-div').addClass("passiveNetwork");
    let moduleContentTarget = getMainModuleRow();
    //await emitSkeletons();

    //innerCurtainsDown(moduleContentTarget);
    $('#modules-left-div').prepend($('<h2 id="titleForHistory" class="titleForHistory boldCrimson"></h2>'));

    emitTopItems();
    //emitSkeletonsAndInnerize();
}
function emitTopItems() {
    let target = $('#modules-left-div');

    let titleDiv = $('<div class="w-75"></div>');
    target.append(titleDiv);
    titleDiv.append('<span class="me-4">find experts yada</span>');
    titleDiv.append('<input type="text" class="ms-4"/></input>');
    titleDiv.append('<button class="ms-4 me-4">search</button>');
    titleDiv.append(getEltBackTo('/search', 'Search'));
}

function emitSkeletons() {
    emitSkeletonLhs();
}

function emitSkeletonLhs() {
    let target = $('#modules-left-div');

    emitSkeletonsAndInnerize(target, "top", "Title etc.");
}

function untentavize(elt) {
    elt.closest(`.${gCommon.tentative}`).removeClass(gCommon.tentative);
    elt.parent().find(`.loadInProgress`).remove();
}

function tentativizeAndInnerize(target, innerKey, tempTitle) {
    let tentativeContainer = $(`<div class="${gCommon.tentative}"></div>`);
    let loadingDiv = $(`<div class="loadInProgress">${tempTitle} Loading</div>`);
    let innerDiv = $(`<div class="innerTarget"></div>`);

    target.append(tentativeContainer);
    tentativeContainer.append(loadingDiv);
    tentativeContainer.append(innerDiv);

    fleshyTarget.set(innerKey, innerDiv);

    return tentativeContainer;
}

function emitSkeletonsAndInnerize(target, innerKey, tempTitle) {
    tentativizeAndInnerize(target, innerKey, tempTitle);
}



