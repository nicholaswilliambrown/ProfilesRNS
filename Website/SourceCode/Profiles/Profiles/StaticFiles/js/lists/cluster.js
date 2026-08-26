gLists.cluster = {
    setup: async () => {
        await getPeopleListInfo();

        console.log('cluster');
        gLists.currentTab = 'cluster';

        await parseClusterTabData(gLists.people);
    }
};

async function parseClusterTabData(people) {
    let target = $('#clusterContent');
    if (people.length == 0) {
        noPeopleOnList(target);
    }
    else {
        let url = `${g.profilesRootURL}/Lists/Default.aspx/Cluster`;

        await jQuery.getJSON(url, function (jsData) {
            console.log('cluster data:', jsData);
            gLists.cluster.data = jsData;

            // cluster data assumed to be moduleFoo[0]
            clusterParse([gLists.cluster.data], emitClusterText);
        })
        .fail(xhrFail);
    }
}
