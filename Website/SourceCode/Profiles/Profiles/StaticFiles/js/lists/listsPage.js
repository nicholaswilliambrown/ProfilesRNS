// this JS should load before the other tab-JS, so they can use gLists
let gLists = {};

gLists.manage = {
    setup: async () => {
        console.log('manage');
        specialHandling();

        await prepareManagePage();
    }
};

async function prepareManagePage() {
    let manageTabData = JSON.parse(g.preLoad);
    console.log('Manage Tab, aka preLoad, data: ', manageTabData);

    gLists.manage.people = manageTabData.ListItems;
    gLists.manage.numPeople = gCommon.numPersons = gLists.manage.people.length;
    gLists.manage.institutions = manageTabData.Institutions;
    gLists.manage.facultyRanks = manageTabData.FacultyRanks;

    await commonSetup();

    setTabTitleAndOrFavicon(`My Person List (${gLists.manage.numPeople})`);
    setupScrolling();

    let main = $('#mainDiv');
    let tabs = $('#mainTabs');
    moveContentTo(tabs, main);

    $('.nav-item').on('click', adjustTab);

    parseManageTabData(gLists.manage.people);
}

function adjustTab(e) {
    let ariaCurr = 'aria-current';
    let tabs = $('.mainTabItem').find('.tab');
    $('.mainTabsContent').hide();

    let target = $(e.target);
    let spanTarget = target.find('span');
    if (!spanTarget.length) { // presumably b/c target is a span and find() looks at children, not self
        spanTarget = target;
    }

    if (spanTarget.hasClass('active')) { // click on current tab should be no-op
        return;
    }
    tabs.removeAttr(ariaCurr);
    tabs.removeClass('active');

    spanTarget.attr(ariaCurr, 'page');
    spanTarget.addClass('active');

    let tabFlavor = spanTarget.attr('id');

    $(`#${tabFlavor}content`).show();
    console.log('flavor is: ', tabFlavor);
    console.log('setup is: ', gLists[tabFlavor].setup);
    gLists[tabFlavor].setup();
}

function parseManageTabData(people) {
    if ( ! gCommon.numPersons) {
        $('#noPeople').removeClass('d-none');
    } else {
        parseSomePeople(people);
    }
}
function parseSomePeople(people) {
        $('#somePeople').removeClass('d-none');
        let target = $('#somePeople');
        somePeopleFirstSection(people, target);
        somePeopleTable(people, target);
}
function somePeopleFirstSection(people, target) {
    if (gCommon.numPersons != 1) { // == 1 is default html
        let currentNumText = `are currently <span class="redBold">${gCommon.numPersons}</span> people`;
        let allPeopleShownText = `all ${gCommon.numPersons} people shown`

        $('#currentNum').html(currentNumText);
        $('#allPeopleShown').html(allPeopleShownText);
    }
    filterSelects(people, target);

    let colSpecs = [newColumnSpec(`${gCommon.cols3}`, 'Name'), newColumnSpec(`${gCommon.cols4}`, 'Institution'),
        newColumnSpec(`${gCommon.cols3}`, 'Faculty Rank'), newColumnSpec(`${gCommon.cols2}`, 'Remove')];
    makeRowWithColumns(target, 'ListHeader', colSpecs, 'bold');
}
function filterSelects(people, target) {
    let colSpecs0 = [newColumnSpec(`${gCommon.cols4}`, 'Institution'), newColumnSpec(`${gCommon.cols4}`, 'Faculty Rank'),
        newColumnSpec(`${gCommon.cols5}`, '')];

    let rowId = 'filterSelects';
    let row = makeRowWithColumns(target, rowId, colSpecs0, 'bold mb-2');

    let institutionSelect = $('<select class="ms-1"><option>(all institutions)</option></select>');
    let facultySelect = $('<select class="ms-1"><option>(all faculty ranks)</option></select>');
    row.find(`#${rowId}Col0`).append(institutionSelect);
    row.find(`#${rowId}Col1`).append(facultySelect);

    for (let i=0; i<gLists.manage.institutions; i++) {
        let institution = gLists.manage.institutions[i];
        let option = $(`<option value=${institution.Value}>${institution.Text}`);
        institutionSelect.append(option);
    }
    for (let i=0; i<gLists.manage.facultyRanks; i++) {
        let rank = gLists.manage.institutions[i];
        let option = $(`<option value=${rank.Value}>${rank.Text}`);
        facultySelect.append(option);
    }
}
function somePeopleTable(people, target) {
    for (let i = 0; i < people.length; i++) {
        let peep = people[i];
        let colSpecs = [newColumnSpec(`${gCommon.cols3}`, peep.DisplayName), newColumnSpec(`${gCommon.cols4}`, peep.InstitutionName),
            newColumnSpec(`${gCommon.cols3}`, peep.FacultyRank), newColumnSpec(`${gCommon.cols2}`)];

        let id = 'person' + i;
        makeRowWithColumns(target, id, colSpecs);
    }
}
function specialHandling() {
    $("#deleteAllFromListA").off().on("click", listsPageDeleteAll);
}
function listsPageDeleteAll() {
    // window.location.refresh();
    return false;
}