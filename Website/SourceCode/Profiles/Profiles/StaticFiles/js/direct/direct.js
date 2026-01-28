gDirect.colSpecs = [
    newColumnSpec(`${gCommon.cols9or12} ps-1`),
    newColumnSpec(`${gCommon.cols3or12} ps-2 d-flex justify-content-center`)
];

async function setupDirectPage() {
    await commonSetup('Search Other Institutions');
    $('#modules-right-div').addClass("passiveNetwork");
    let moduleContentTarget = getMainModuleRow();
    //await emitSkeletons();

    //innerCurtainsDown(moduleContentTarget);

    emitTopItems();
    emitSkeletons();
}
function emitTopItems() {
    let target = $('#modules-left-div');

    let backToRow = makeRowWithColumns(target, 'backTo', gDirect.colSpecs, "ps-2 mb-2 mb-lg-0 w-100");
    let backToElt = getEltBackTo('/search', 'Search');
    backToRow.find('#backToCol1').html(backToElt);

    let titleDiv = $('<div class="w-100"></div>');
    target.append(titleDiv);
    titleDiv.append('<span class="me-4">Find experts across multiple institutions.</span>');

    let keywordsDiv = $('<div id="keywordSearch" class="ps-3 bordCcc w-75 mt-2 mb-3"></div>');
    keywordsDiv.append('<label class="bold" for="keywordInput">Keywords</label>');
    keywordsDiv.append('<input id="keywordInput" type="text" class="ms-4"/></input>');

    let searchSpan = $('<span class="ms-3" alt="Search"></span>');
    let searchButton = $(`<img class="directSearchButton" src="${gBrandingConstants.jsSearchImageFiles}search.jpg"/>`);
    keywordsDiv.append(searchSpan);
    keywordsDiv.append(searchButton);

    target.append(keywordsDiv);

    target.append('<div class="me-4">Below are the number of matching people at each institution. Click an institution\'s name to view the list of people.</div>');
}

function emitSkeletons() {
    let keyword = tryMatchUrlParam(/keyword=(.*?)(&|$)/i);
    let baseDirectUrl = "http://localhost:55956/DIRECT/DIRECTSVC.aspx/getdata?";

    let target = $('#modules-left-div');
    let siteTable = $('<div class="mt-4"></div>');
    target.append(siteTable);

    let sites = JSON.parse(g.preLoad);
    for (sites of sites) {
        let siteID = sites.SiteID;
        let SiteName = sites.SiteName;

        let rowId = `row${siteID}`;
        let row = makeRowWithColumns(siteTable, rowId, gDirect.colSpecs, "ps-2 w-100 bordCcc");
        row.find(`#${rowId}Col0`).html(SiteName);
        row.find(`#${rowId}Col0`).addClass('bendCcc');

        let resultDiv = row.find(`#${rowId}Col1`);
        resultDiv.html('<span class="loadInProgress">Loading</span>');

        let queryString = `siteID=${siteID}&searchQuery=${keyword}`;
        let url = baseDirectUrl + queryString;
        $.ajax({
            url: url,
            success: (data) => {
                resultDiv.html(data);
                },
            timeout: 4000, // ms
            error: (jqXHR, textStatus, errorThrown) => {
                resultDiv.html(errorThrown);
                }
        });
    }
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



