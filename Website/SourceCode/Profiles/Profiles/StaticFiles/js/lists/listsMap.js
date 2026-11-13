gLists.map = {
    setup: async () => {
        await getPeopleListInfo();

        console.log('setting up for map!');
        gLists.currentTab = 'map';
        target = $('#mapContent');

        let options = {
            target: target,
            tableId: 'savedListsForMap',
            isSavedListsTab: false,
            labelForRefresh: 'Refresh Map',
            getLists: getMapDataForSelectedLists
        }
        await setupSavedListsTable(options);

        let mapDisplayDiv = $('<div id="mapDisplayDiv"></div>');
        target.append(mapDisplayDiv);
        await getMapDataForSelectedLists([0]);
    }
};

// pass in an array of ids
async function getMapDataForSelectedLists(listIds) {
    let url = `${g.profilesRootURL}/Lists/Default.aspx/SavedListsMap`;
    let commaListIds = listIds.join(',');

    await $.post(url, {listIds: commaListIds}, function(result) {
        gLists.savedLists.map = JSON.parse(result);
        console.log('Saved Lists People Data: ', gLists.savedLists.map);

        augmentPeopleForMap();
    });
    await parseMapTabData($('#mapDisplayDiv'));
}
function augmentPeopleForMap() {
    if (gLists.savedLists.map.Groups.length > 1) {
        for (let peop of gLists.savedLists.map.people) {
            peop.display_name += ` (listed in: ${peop.listNames})`;
        }
    }
}
async function parseMapTabData(target) {
    console.log('SavedLists map data: ', gLists.savedLists.map);

    let people = gLists.savedLists.map.people;
    if (people.length == 0) {
        noPeopleOnList(target);
    }
    else {
        await mapParse(gLists.savedLists.map, '', target);
    }
}
