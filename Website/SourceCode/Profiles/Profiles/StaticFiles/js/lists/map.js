gLists.map = {
    setup: async () => {
        console.log('setting up for map!');

        if (!gLists.map.done) {
            await parseMapTabData((gLists.manage.people));
            gLists.map.done = true;
        }


    }
};

function parseMapTabData(people) {
    let target = $('#mapContent');
    target.append($("<div>Possible map</div>"));
    if (people.length == 0) {
        noPeopleOnList(target);
    }
    else {
        target.append("<div>Here comes the map</div>");
    }
}
