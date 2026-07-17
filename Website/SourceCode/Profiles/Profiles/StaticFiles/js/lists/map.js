gLists.map = {
    setup: () => {
        console.log('setting up for map!');

        if (!gLists.map.done) {
            parseMapTabData(gLists.manage.people);
            gLists.map.done = true;
        }
    }
};

function parseMapTabData(people) {
    let target = $('#mapContent');
    if (people.length == 0) {
        noPeopleOnList(target);
    } else {
        target.append("<div>Here comes the map</div>");

        let firstNodeId = people[0].NodeID;
        let predicateForListMap = 963;
        let jsonTmp = [];
        let url = `${g.profilesRootURL}/Lists/Default.aspx/Map`;

        jQuery.getJSON(url, function (jsData) {
            console.log(jsData);
            gLists.map.data = jsData;
            mapParse(gLists.map.data, "listed people");
        })
            .fail(function (jqXHR, textStatus, errorThrown) {
                console.error("Request failed!");
                console.error("Status: " + textStatus); // Common outputs: "error", "timeout", "parsererror"
                console.error("Error Thrown: " + errorThrown); // Common outputs: "Not Found", "Internal Server Error"
                console.error("HTTP Status Code: " + jqXHR.status); // e.g., 404, 500;
            });
    }
}
