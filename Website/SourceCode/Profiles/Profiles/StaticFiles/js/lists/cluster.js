gLists.cluster = {
    setup: () => {
        console.log('cluster');
        if (!gLists.cluster.done) {
            parseClusterTabData(gLists.manage.people);
            gLists.cluster.done = true;
        }
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
            .fail(function (jqXHR, textStatus, errorThrown) {
                console.error("Request failed!");
                console.error("Status: " + textStatus); // Common outputs: "error", "timeout", "parsererror"
                console.error("Error Thrown: " + errorThrown); // Common outputs: "Not Found", "Internal Server Error"
                console.error("HTTP Status Code: " + jqXHR.status); // e.g., 404, 500;
            });
    }
}
