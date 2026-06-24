// this JS should load before the other tab-JS, so they can use gLists
let gLists = {};

gLists.manage = {
    setup: () => {
        console.log('manage');
        parseLists(gLists.manage.people);
    }
};

async function setupListsPage() {
    let peopleListData = JSON.parse(g.preLoad);
    let people = peopleListData.ListItems;
    let numPeople = people.length;
    console.log('Listed Folks', people);

    gLists.manage.people = people;
    gCommon.numPersons = numPeople;
    await commonSetup();

    setTabTitleAndOrFavicon(`My Person List (${numPeople})`);
    setupScrolling();

    let main = $('#mainDiv');
    let tabs = $('#mainTabs');
    moveContentTo(tabs, main);

    $('.nav-item').on('click', adjustTab);

    gLists.manage.setup();

    specialHandling();
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

function parseLists(people) {
    let numPeople = people.length;
    if ( ! numPeople) {
        $('#noPeople').removeClass('d-none');
    } else {
        $('#somePeople').removeClass('d-none');

        if (numPeople != 1) { // == 1 is default html
            let currentNumText = `are currently <span class="redBold">${numPeople}</span> people`;
            let allPeopleShownText = `all ${numPeople} people shown`

            $('#currentNum').html(currentNumText);
            $('#allPeopleShown').html(allPeopleShownText);
        }

        let target = $('#somePeople');
        let colSpecs0 = [newColumnSpec(`${gCommon.cols3}`, 'Person'), newColumnSpec(`${gCommon.cols3}`, 'Department'), newColumnSpec(`${gCommon.cols3}`, 'Institution'), newColumnSpec(`${gCommon.cols3}`, 'Faculty Rank'),];
        makeRowWithColumns(target, 'ListHeader', colSpecs0);

        for (let i = 0; i < people.length; i++) {
            let peep = people[i];

            let colSpecs = [newColumnSpec(`${gCommon.cols3}`, peep.DisplayName), newColumnSpec(`${gCommon.cols3}`, peep.DepartmentName), newColumnSpec(`${gCommon.cols3}`, peep.InstitutionName), newColumnSpec(`${gCommon.cols3}`, peep.FacultyRank),];

            let id = 'person' + i;
            makeRowWithColumns(target, id, colSpecs);
        }
    }
}
function specialHandling() {
    $("#deleteAllFromListA").off().on("click", listsPageDeleteAll);
}
function listsPageDeleteAll() {
    // window.location.refresh();
    return false;
}