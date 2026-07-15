gLists.map = {
    setup: async () => {
        console.log('setting up for map!');

        if (!gLists.map.done) {
            await parseMapTabData((gLists.manage.people));
            gLists.map.done = true;
        }


    }
};

async function parseMapTabData(people) {
    let target = $('#mapContent');
    if (people.length == 0) {
        noPeopleOnList(target);
    }
    else {
        target.append("<div>Here comes the map</div>");

        let firstNodeId = people[0].NodeID;
        let predicateForListMap = 963;
        let url = `${g.profilesRootURL}/ProfileJsonSvc.aspx/getdata?s=${firstNodeId}&p=${predicateForListMap}&t=map`;
        await jQuery.getJSON(jsonURL, function (json2) {
            for (let j2=0; j2<json2.length; j2++) {
                let jsonJ2 = json2[j2];
                jsonTmp.push(jsonJ2)
            }
            g.pageJSON = jsonTmp;
        });

    }
}
