// this JS should load before the other tab-JS, so they can use gLists
let gLists = {};

gLists.noRank = '--';
gLists.manage = {
    setup: async () => {
        await loginGuard();

        $('.modalupdate').hide();

        console.log('manage');
        gLists.currentTab = 'manage';

        if (!gLists.manage.done) {
            await prepareManagePage();
            specialHandling();
            gLists.manage.done = true;
        }
    }
};
async function loginGuard() {
    // must be logged in to see lists page
    if (!sessionInfo.userID) {
        await $('body').empty();
        console.log('You must be logged in to visit Lists pages.');
        window.location.href = `${g.profilesRootURL}/Search`;
    }
}
async function prepareManagePage() {

    if ( ! gLists.manage.people) {

        let manageTabData;
        let currentUrl = new URL(window.location.href);
        let listUrl = new URL(`${g.profilesRootURL}/Lists/Default.aspx/GetList`);
        listUrl.search = currentUrl.search;

        await $.get(listUrl.toString(), function(result) {
            manageTabData = JSON.parse(result);
        });

        console.log('Manage Tab, aka preLoad, data: ', manageTabData);
        gLists.manage.people = manageTabData.ListItems;
        gLists.manage.numPeople = gCommon.numPersons = gLists.manage.people.length;
        gLists.manage.institutions = manageTabData.Institutions;
        gLists.manage.facultyRanks = manageTabData.FacultyRanks;

        $('#numPersonsSpan').html(gLists.manage.numPeople);
    }

    await commonSetup();

    setTabTitleAndOrFavicon(`My Person List (${gLists.manage.numPeople})`);
    setupScrolling();

    let main = $('#mainDiv');
    let tabs = $('#mainTabs');
    moveContentTo(tabs, main);

    $('.nav-item').on('click', adjustToClickedTab);
    $('#removeAll').on('click', removeAllPersons);
    $('#replaceWithCoauthors').on('click', replaceWithCoauthors);
    $('#addCoauthors').on('click', addCoauthors);

    let target = $('#peopleDiv');

    hideAllTabContent();
    showThisTabContent($('#manage'));
    parsePersonListData(gLists.manage.people, target, true);

    let tab = trySearchUrlParam('tab');
    if (tab) {
        $(`#${tab}`).click();
    }
}

function hideAllTabContent() {
    let inactives = $('#tabsUl').find('span');
    inactives.removeClass('active');
    inactives.removeAttr('aria-current');
    inactives.each(function(index, elt) {
        let tabFlavor = $(elt).attr('id');
        $(`#${tabFlavor}Content`).hide();
    });
}
function showThisTabContent(spanTarget) {
    spanTarget.attr('aria-current', 'page');
    spanTarget.addClass('active');

    let tabFlavor = spanTarget.attr('id');
    $(`#${tabFlavor}Content`).show();

    return tabFlavor;
}
function adjustToClickedTab(e) {
    let target = $(e.target);
    let spanTarget = target.find('span');
    if (!spanTarget.length) { // presumably b/c target is a span and find() looks at children, not self
        spanTarget = target;
    }

    if ( ! spanTarget.hasClass('active')) { // click on current tab should be no-op
        hideAllTabContent();
        let tabFlavor = showThisTabContent(spanTarget);

        console.log('flavor is: ', tabFlavor);
        console.log('setup is: ', gLists[tabFlavor].setup);
        gLists[tabFlavor].setup();
    }
}

function noPeopleOnList(target) {
    target.html($(`<div class="mt-2 bold" id="noPeople">
                        You currently have no people in your list.
                    </div>`))
}
function parsePersonListData(people, target, isManage) {
    gLists.isManage = isManage ? isManage : false;
    if (!isManage) {
        target.append($('<div id="currentListPeople" class="bold ps-0 ms-0">My Current List</div>'));
    }

    let currentPeopleTable = $(`<div id="currentPeopleTable"></div>`);
    target.append(currentPeopleTable);

    let noPeopleTarget = isManage ? $("#manageContent") : $("#currentPeopleTable");
    if (people.length == 0) {
        noPeopleOnList($(noPeopleTarget));
    }
    else {
        emitTopOfPersonTable(people, target, isManage);
        emitPersonRowsAndButtons(people, target, isManage);
    }
}

function setupListAndPagination(itemsTarget, people, pageSizes, pagingTarget, label) {
    let pagination = new PagingCached(people, pageSizes, emitPersonRows, itemsTarget, pagingTarget, label);
    pagination.display(itemsTarget);
    pagination.emitPagingRow(pagingTarget);
}
function  emitTopOfPersonTable(people, target, isManage) {
    if (gCommon.numPersons != 1) { // == 1 is default html
        let currentNumText = `are currently <span class="redBold">${gCommon.numPersons}</span> people`;
        let allPeopleShownText = `all ${gCommon.numPersons} people shown`

        $('#currentNum').html(currentNumText);
        $('#allPeopleShown').html(allPeopleShownText);
    }

    if (isManage) {
        filterSelects(people, target, isManage);
    }

    let colSpecs = [newColumnSpec(`${gCommon.cols4} bordE p-1`, 'Name'),
            newColumnSpec(`${gCommon.cols4} bordE p-1`, 'Institution'),
            //newColumnSpec(`${isManage ? gCommon.cols3 : gCommon.cols4} bordE p-1`, 'Faculty Rank')];
            newColumnSpec(`${gCommon.cols3} bordE p-1`, 'Faculty Rank')];
    //if (isManage) {
        colSpecs.push(newColumnSpec(`${gCommon.cols1} p-1`, 'Remove'));
    //}

    makeRowWithColumns(target, 'ListHeader', colSpecs, 'listsTableHeader bord9 myMs-0');
}
function filterSelects(people, target) {
    let colSpecs0 = [   newColumnSpec(`${gCommon.cols6}`, 'Institution'),
                        newColumnSpec(`${gCommon.cols4}`, 'Faculty Rank'),
                        newColumnSpec(`${gCommon.cols2}`, '')];

    let rowId = 'filterSelects';
    let row = makeRowWithColumns(target, rowId, colSpecs0, 'bold mb-2 myMs-0');

    let institutionSelect = $(`<select id="institutionSelect" class="ms-1"><option value="">(all institutions)</option></select>`);
    let facultySelect = $(`<select id="facultySelect" class="ms-1"><option value="">(all faculty ranks)</option></select>`);
    row.find(`#${rowId}Col0`).append(institutionSelect);
    row.find(`#${rowId}Col1`).append(facultySelect);

    let institutionQp = trySearchUrlParam('institution');
    let facultyQp = trySearchUrlParam('facultyrank');

    for (let i=0; i<gLists.manage.institutions.length; i++) {
        let institution = gLists.manage.institutions[i];
        let text = institution.Text;
        let option = $(`<option value="${text}">${text}</option>`);
        if (text == institutionQp) {
            option.attr('selected', true);
        }
        institutionSelect.append(option);
    }
    for (let i=0; i<gLists.manage.facultyRanks.length; i++) {
        let rank = gLists.manage.facultyRanks[i];
        let text = rank.Text;
        if (text == '') {
            text = '--';
        }
        let option = $(`<option value="${text}">${text}</option>`);
        if (text == facultyQp) {
            option.attr('selected', true);
        }
        facultySelect.append(option);
    }

    institutionSelect.on('change', instOrFacChange);
    facultySelect.on('change', instOrFacChange);
}
function instOrFacChange(e) {
    let typeQp = tryMatchUrlParam(/type=(.*(;|$))/);
    let keys = typeQp ? ['type'] : [];
    let vals = typeQp ? [typeQp] : [];

    let institutionSelect = $('#institutionSelect');
    let facultySelect = $('#facultySelect');

    keys = keys.concat(['institution', 'facultyrank', 'tab']);

    let instVal = decodeURIComponent(institutionSelect.val());
    let facVal = decodeURIComponent(facultySelect.val());
    let tabVal = gLists.currentTab;

    vals = vals.concat([instVal, facVal, tabVal]);

    filterPersonList(keys, vals);
}
function filterPersonList(keys, vals) {
    let result = null;

    let currentUrl = new URL(window.location.href);
    let currentUrlString = encodeURI(currentUrl.toString());

    let newUrl = new URL(gCommon.viewMyListUrl)
    for (let i=0; i<keys.length; i++) {
        if (String(vals[i]) != '') {
            newUrl.searchParams.set(keys[i], vals[i]);
        }
    }
    let newUrlString = encodeURI(newUrl.toString());
    if (currentUrlString != newUrlString) {
        window.location.href = newUrlString;
    }
    return result;
}
function emitPersonRows(people, target) {
    target.empty();

    for (let i = 0; i < people.length; i++) {
        let person = people[i];
        if (person.FacultyRank == '') {
            person.FacultyRank = gLists.noRank;
        }

        let rowId = 'person' + i;
        let checkboxId = `${rowId}-removalCheck`;
        let removalCheckbox = $(`<input type="checkbox" pid="${person.PersonID}" class="removalCheck" id="${checkboxId}"/>`);

        let colSpecs = [newColumnSpec(`${gCommon.cols4} linked bordE`, person.DisplayName),
                        newColumnSpec(`${gCommon.cols4} linked bordE`, person.InstitutionName),
                        //newColumnSpec(`${gLists.isManage ? gCommon.cols3 : gCommon.cols4} linked bordE`, person.FacultyRank)];
                        newColumnSpec(`${gCommon.cols3} linked bordE`, person.FacultyRank)];
        //if (gLists.isManage) {
            colSpecs.push(newColumnSpec(`${gCommon.cols1} d-flex justify-content-center p-1`, removalCheckbox));
        //}

        let row = makeRowWithColumns(target, rowId, colSpecs, 'bord9_3 highlightHover myMs-0');

        let profileLink = `${g.profilesRootURL}/display/${person.NodeID}`;
        let linkFn = () => {
            window.location.href = profileLink
        };
        row.find(`.linked`).on('click', linkFn);
    }
}
function emitPersonRowsAndButtons(people, outerTarget, isManage) {
    let peopleRows = $(`<div id="peopleRows"></div>`);
    outerTarget.append(peopleRows);

    let colSpecs = [newColumnSpec(`${gCommon.cols12} d-flex justify-content-center`)];
    let pagingRow = makeRowWithColumns(outerTarget, 'pagingRow', colSpecs, 'bord9_3 pt-1 pb-1 myMs-0');

    let debug = 1;
    if (debug) {
        for (let i=0; i<people.length; i++) {
            let person = people[i];
            if (!person.DisplayName.match(/^\d+\./)) {
                person.DisplayName = String(i+1) + ". " + person.DisplayName;
            }
        }
    }

    setupListAndPagination(peopleRows, people, [15, 25, 50, 100], pagingRow, gLists.currentTab);

    //if (isManage) {
        let button = $(`<button class="btn gradientLists" id="removalButton${gLists.currentTab}">Remove Selected People</button>`);
        button.on('click', removeSelectedPersons);
        let colSpecs2 = [newColumnSpec(`${gCommon.cols12} d-flex justify-content-end pe-0`, button)];
        makeRowWithColumns(outerTarget, 'removalRow${gLists.currentTab}', colSpecs2, 'mt-1 myMs-0');
    //}
}

async function removeSelectedPersons(e) {
    e.preventDefault();
    let url = `${g.profilesRootURL}/Lists/Default.aspx/DeleteSelected`
    let selected = $(`.removalCheck:checked`);
    let selectedPids = [];
    selected.each(function () {
        let pid = $(this).attr('pid');
        selectedPids.push(pid);
    });

    console.log(`Want to remove: `, selectedPids);
    let dataObject = {
        listId: sessionInfo.listID,
        personIds: selectedPids.join(',')
    };

    await $.post(url, dataObject)
        .done(function (result) {
            console.log(`Result: ${result}`);
        })
        .fail(xhrFail);

    window.location.reload();
}
async function removeAllPersons(e) {
    localOnlyEvent(e);
    if (confirm('Are you sure you want to remove all people from your list?')) {

        let url = `${g.profilesRootURL}/Lists/Default.aspx/ClearList`
        await $.get(url, function (result) {
            console.log('Result: ', JSON.parse(result));
        });
        window.location.reload();
    }
}
async function addCoauthors(e) {
    e.preventDefault();

    let url = `${g.profilesRootURL}/Lists/Default.aspx/AddCoauthors`

    await $.get(url);
    window.location.reload();
}
async function replaceWithCoauthors(e) {
    e.preventDefault();

    let url = `${g.profilesRootURL}/Lists/Default.aspx/ReplaceWithCoauthors`

    await $.get(url);
    window.location.reload();
}
function specialHandling() {
    $("#deleteAllFromListA").off('click');
    $("#deleteAllFromListA").on("click", removeAllPersons);
}
function xhrFail (jqXHR, textStatus, errorThrown) {
    console.error("Request failed!");
    console.error("Status: " + textStatus); // Common outputs: "error", "timeout", "parsererror"
    console.error("Error Thrown: " + errorThrown); // Common outputs: "Not Found", "Internal Server Error"
    console.error("HTTP Status Code: " + jqXHR.status); // e.g., 404, 500;
}
function refreshToTab(tab) {
    if (!tab) {
        tab = gLists.currentTab
    }
    let refreshUrl = new URL(window.location.href);
    refreshUrl.searchParams.set('tab', tab);

    window.location.href = refreshUrl.toString();
}