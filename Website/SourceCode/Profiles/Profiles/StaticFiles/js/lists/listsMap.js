gLists.map = {
    setup: async () => {
        await getPeopleListInfo();

        console.log('setting up for map!');
        gLists.currentTab = 'map';

        let target = $('#mapContent');
        await setupSavedListsTable(target, 'savedListsForMap');
        await setupInitialMapData();

        await parseMapTabData(target);
    }
};
async function getSavedListsForMap(listIds) {
    let url = `${g.profilesRootURL}/Lists/Default.aspx/SavedListsMap`;
    let commaListIds = listIds.join(',');

    await $.post(url, {listIds: commaListIds}, function(result) {
        gLists.savedLists.map = JSON.parse(result);
        console.log('SavedLists from  post: ', gLists.savedLists.map);
    });
}

async function setupInitialMapData() {
    await getSavedListsForMap([0]); // 0 indicates the initial 'current list'
}

async function parseMapTabData(target) {
    // backward sanity
    let url = `${g.profilesRootURL}/Lists/Default.aspx/Map`;

    await jQuery.getJSON(url, function (jsData) {
        gLists.map.data = jsData;
        console.log('Classic map data: ', gLists.map.data);
    }).fail(xhrFail);

    console.log('SavedLists map data: ', gLists.savedLists.map);

    let people = gLists.savedLists.map.people;
    if (people.length == 0) {
        noPeopleOnList(target);
    }
    else {
        await mapParse(gLists.savedLists.map, '', $('#mapContent'));
    }


}
