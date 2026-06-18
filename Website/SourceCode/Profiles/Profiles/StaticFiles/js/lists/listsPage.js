let gLists = {};

async function setupListsPage() {
    let peopleListData = JSON.parse(g.preLoad);
    let people = peopleListData.ListItems;
    let numPeople = people.length;
    console.log('Listed Folks', people);

    gCommon.numPersons = numPeople;
    await commonSetup();

    setTabTitleAndOrFavicon(`My Person List (${numPeople})`);
    setupScrolling();

    let main = $('#mainDiv');
    let tabs = $('#mainTabs');
    moveContentTo(tabs, main);

    $('.nav-item').on('click', adjustTab);

    gLists.manage.data = people;

    parseLists($('#manageContent'), people);
}
function initTabs() {
    gLists = {
        manage: {},
        map: {},
        cluster: {},
        reports: {},
        export: {},
        savedLists: {},
    };
    gLists.manage.setup = () => {
        console.log('landing-manage');
        // perhaps:
        //location.reload();
    }
}
function adjustTab(e) {
    let ariaCurr = 'aria-current';
    let target = $(e.target);

    let tabs = $('.mainTabItem').find('.tab');
    tabs.removeAttr(ariaCurr);
    tabs.removeClass('active');
    $('.mainTabsContent').hide();

    target.attr(ariaCurr, 'page');
    target.addClass('active');

    let tabFlavor = target.attr('id');
    $(`#${tabFlavor}content`).show();
    gLists[tabFlavor].setup();
}
function parseLists(target, people) {

    let colSpecs0 = [
        newColumnSpec(`${gCommon.cols3}`, 'Person'),
        newColumnSpec(`${gCommon.cols3}`, 'Department'),
        newColumnSpec(`${gCommon.cols3}`, 'Institution'),
        newColumnSpec(`${gCommon.cols3}`, 'Faculty Rank'),
    ];
    makeRowWithColumns(target, 'ListHeader', colSpecs0);

    for (let i = 0; i < people.length; i++) {
        let peep = people[i];

        let colSpecs = [
            newColumnSpec(`${gCommon.cols3}`, peep.DisplayName),
            newColumnSpec(`${gCommon.cols3}`, peep.DepartmentName),
            newColumnSpec(`${gCommon.cols3}`, peep.InstitutionName),
            newColumnSpec(`${gCommon.cols3}`, peep.FacultyRank),
        ];

        let id = 'person' + i;
        makeRowWithColumns(target, id, colSpecs);
    }
}

// html should load this file before the JS for each tab
initTabs();
