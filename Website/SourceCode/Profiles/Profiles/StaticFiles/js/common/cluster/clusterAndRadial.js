function showAndHideClasses(toShow, toHide) {
    $(`.${toShow}`).show();
    $(`.${toHide}`).hide();
}
function getPersonId(jsonData) {
    let personMatch = jsonData.NetworkPeople.filter(p => p.d == 0);
    let result;

    if (personMatch.length > 0) {
        result = personMatch[0].id;
    }
    else { // no specific 'center' person, just choose one
        result = jsonData.NetworkPeople[0];
    }
    return result;
}
function emitTextCoauthors(target, coauthors, connections, personId) {
    target.append($(`<div class="mb-2"><strong>${gCoauthor.coauthorsWithDash}</strong></div>`));
    let colSpecs = [
        newColumnSpec(`${gCommon.cols3or12} bordE`, spanify('<strong>Name</strong>')),
        newColumnSpec(`${gCommon.cols2or12} bordE`, spanify('<strong>Total Publications</strong>')),
        newColumnSpec(`${gCommon.cols3or12} bordE`, spanify('<strong>Co-Authored Publications</strong>')),
        newColumnSpec(`${gCommon.cols4or12} `, spanify('<strong>Most Recent Co-Authored Publication</strong>'))
    ];
    makeRowWithColumns(target, `tcoath`, colSpecs, "borderOneSolid me-3 ms-1 stripe");

    for (let i=0; i<coauthors.length; i++) {
        let coauthor = coauthors[i];
        let stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";

        let numCopubs = gCommon.NA;
        let recent = gCommon.NA;
        let coauthId = Number(coauthor.id);
        let authorId = Number(personId);
        let coauthUri = coauthor.uri;

        let connection = connections.find(conn =>
            (conn.id1 == authorId && conn.id2 == coauthId) ||
            (conn.id1 == coauthId && conn.id2 == authorId));

        if (connection) {
            numCopubs = String(connection.n);
            recent = String(connection.y2);
        }

        let link = createAnchorElement(`${coauthor.ln}, ${coauthor.fn}`, coauthUri);
        colSpecs = [
            newColumnSpec(`${gCommon.cols3or12} bordE`, link),
            newColumnSpec(`${gCommon.cols2or12}`, spanify(coauthor.pubs)),
            newColumnSpec(`${gCommon.cols3or12} bordS`, spanify(numCopubs)),
            newColumnSpec(`${gCommon.cols4or12} bordS`, spanify(recent))
        ];
        let row = makeRowWithColumns(target, `tcoath-${i}`, colSpecs,
            `borderOneSolid me-3 ms-1 ${stripeClass}`);
        hoverLight(row);
    }
}
function emitTextCoauthorsOfCoauthors(target, coauthorsOfCoauthors) {
    target.append($(`<div class="mt-4 mb-2"><strong>
        ${gCoauthor.coauthorsWithDash} of ${gCoauthor.coauthorsWithDash}</strong></div>`));
    let colSpecs = [
        newColumnSpec(`${gCommon.cols6or12} bordE`, spanify('<strong>Name</strong>')),
        newColumnSpec(`${gCommon.cols6or12} bordS`, spanify('<strong>Total Publications</strong>')),
    ];
    makeRowWithColumns(target, `tcoath2`, colSpecs, "borderOneSolid me-3 ms-1 stripe");

    for (let i=0; i<coauthorsOfCoauthors.length; i++) {
        let coOfCo = coauthorsOfCoauthors[i];
        let stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";

        let link = createAnchorElement(`${coOfCo.ln}, ${coOfCo.fn}`, coOfCo.uri);
        let pubs = String(coOfCo.pubs);

        let colSpecs = [
            newColumnSpec(`${gCommon.cols6or12} bordE`, link),
            newColumnSpec(`${gCommon.cols6or12} bordS`, spanify(pubs)),
        ];
        let row = makeRowWithColumns(target, `tcoath2-${i}`, colSpecs,
            `borderOneSolid me-3 ms-1 ${stripeClass}`);

        hoverLight(row);
    }
}
function emitTextCoauthorsConnections(target, coauthorsConnections, networkPeople) {
    target.append($('<div class="mt-4 mb-2"><strong>Co-Author Connections</strong></div>'));
    let colSpecs = [
        newColumnSpec(`${gCommon.cols3or12} bordE`, spanify('<strong>Person 1</strong>')),
        newColumnSpec(`${gCommon.cols3or12} bordE`, spanify('<strong>Person 2</strong>')),
        newColumnSpec(`${gCommon.cols3or12} bordE`, spanify('<strong>Number of Co-Publications</strong>')),
        newColumnSpec(`${gCommon.cols3or12}`, spanify('<strong>Most Recent Co-Publication</strong>'))
    ];
    makeRowWithColumns(target, `tcoathConn`, colSpecs, "borderOneSolid me-3 ms-1 stripe");

    for (let i=0; i<coauthorsConnections.length; i++) {
        let coauthorsConnection = coauthorsConnections[i];
        let stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";

        let sourceP = networkPeople.find(p => p.id == coauthorsConnection.id2);
        let targetP = networkPeople.find(p => p.id == coauthorsConnection.id1);
        let num = String(coauthorsConnection.n);
        let numConnectionUrl = coauthorsConnection.connectionURI;
        let latest = String(coauthorsConnection.y2);

        let link1 = createAnchorElement(`${sourceP.ln}, ${sourceP.fn}`, sourceP.uri);
        let link2 = createAnchorElement(`${targetP.ln}, ${targetP.fn}`, targetP.uri);
        let linkConnection = createAnchorElement(num, numConnectionUrl);

        let colSpecs = [
            newColumnSpec(`${gCommon.cols3or12} bordE`, link1),
            newColumnSpec(`${gCommon.cols3or12} bordE`, link2),
            newColumnSpec(`${gCommon.cols3or12} bordE`, linkConnection),
            newColumnSpec(`${gCommon.cols3or12}`, spanify(latest))
        ];
        let row = makeRowWithColumns(target, `tcoathConn-${i}`, colSpecs,
            `borderOneSolid me-3 ms-1 ${stripeClass}`);

        hoverLight(row);
    }
}

