gLists.cluster = {
    setup: async () => {
        await getPeopleListInfo();

        console.log('cluster');
        gLists.currentTab = 'cluster';

        parseClusterTabData(gLists.manage.people);
    }
};

function parseClusterTabData(people) {
    let target = $('#clusterContent');
    if (people.length == 0) {
        noPeopleOnList(target);
    }
    else {
        let url = `${g.profilesRootURL}/Lists/Default.aspx/Cluster`;

        jQuery.getJSON(url, function (jsData) {
            console.log('cluster data:', jsData);
            gLists.cluster.data = jsData;

            // cluster data assumed to be moduleFoo[0]
            clusterParse([gLists.cluster.data], false, $('#mapContent'));
        })
        .fail(xhrFail);
    }
}
