gLists.map = {
    setup: async () => {
        await getPeopleListInfo();

        console.log('setting up for map!');
        gLists.currentTab = 'map';

        let target = $('#mapContent');
        await setupSavedListsTable(target, 'savedListsForMap');
        parseMapTabData(target, gLists.people);
    }
};

function parseMapTabData(target, people) {
    if (people.length == 0) {
        noPeopleOnList(target);
    }
    else {
        let url = `${g.profilesRootURL}/Lists/Default.aspx/Map`;

        jQuery.getJSON(url, function (jsData) {
            console.log(jsData);
            gLists.map.data = jsData;

            mapParse(gLists.map.data, "listed people", $('#mapContent'));
        })
            .fail(xhrFail);
    }
}
