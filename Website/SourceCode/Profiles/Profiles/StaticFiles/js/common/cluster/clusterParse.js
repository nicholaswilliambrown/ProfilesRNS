async function clusterParse(moduleJson, forGroups) {

    $('.personDisplayName').html(getPersonFirstLastName());

    // add wide and narrow cluster options
    $("#wideClusterGraph").addClass(gCommon.hideXsShowOthers);
    $("#narrowClusterGraph").addClass(`${gCommon.showXsHideOthers} mlMuch`);

    let jsonData = moduleJson.ModuleData ? moduleJson.ModuleData[0] : moduleJson[0];

    displayClusterTab(jsonData, forGroups);

    $(window).resize(function(){
        displayClusterTab(jsonData, forGroups);
    });
}
function displayClusterTab(jsonData, forGroups) {
    $('.clusterView').empty();

    let jsonCopy = JSON.parse(JSON.stringify(jsonData));
    emitClusterGraph(jsonCopy);

    let textDiv = $('#cgTextDiv');
    if (forGroups) {
        emitGroupClusterText(jsonCopy, textDiv)
    }
    else {
        emitClusterText(jsonCopy, textDiv);
    }

    setupClusterGraphTextFlips();
    showClusterAsGraph();
}
function emitClusterText(jsonData, target) {
    let personId = getPersonId(jsonData);
    let coauthors = [];
    let coauthorsOfCoauthors = [];

    let networkPeople = jsonData.NetworkPeople;
    for (let i=0; i<networkPeople.length; i++) {
        let networkPerson = networkPeople[i];
        let distance = networkPerson.d;
        if (distance == 1) {
            coauthors.push(networkPerson);
        }
        else if (distance == 2) {
            coauthorsOfCoauthors.push(networkPerson);
        }
    }
    let fullConnections = jsonData.NetworkCoAuthors;
    let coauthorsConnections = fullConnections
        .filter(coConn =>   coConn.id1 != personId &&
            coConn.id2 != personId);

    emitTextCoauthors(target, coauthors, fullConnections, personId);
    emitTextCoauthorsOfCoauthors(target, coauthorsOfCoauthors);
    emitTextCoauthorsConnections(target, coauthorsConnections, networkPeople);
}
function emitGroupClusterText(jsonData, target) {
    let members = jsonData.NetworkPeople;
    let coauthorsConnections = jsonData.NetworkCoAuthors;

    emitTextMembers(target, members, coauthorsConnections);
    emitTextCoauthorsConnections(target, coauthorsConnections, members);
}
function emitTextMembers(target, members, coauthorsConnections) {
    target.append($(`<div class="mb-2"><strong>${gCoauthor.coauthorsWithDash}</strong></div>`));
    let colSpecs = [
        newColumnSpec(`${gCommon.cols6or12} bordE`, spanify('<strong>Name</strong>')),
        newColumnSpec(`${gCommon.cols6or12}`, spanify('<strong>Total Publications</strong>'))
    ];
    makeRowWithColumns(target, `tmember`, colSpecs, "borderOneSolid me-3 ms-1 stripe");

    for (let i=0; i<members.length; i++) {
        let member = members[i];
        let stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";

        let memberId = Number(member.id);
        let memberUri = member.uri;

        let connection = coauthorsConnections.find(conn =>
            (conn.id1 == memberId || conn.id2 == memberId));

        if (connection) {
            numCopubs = String(connection.n);
            recent = String(connection.y2);
        }

        let link = createAnchorElement(`${member.ln}, ${member.fn}`, memberUri);

        colSpecs = [
            newColumnSpec(`${gCommon.cols6or12} bordE`, link),
            newColumnSpec(`${gCommon.cols6or12}`, spanify(member.pubs))
        ];
        makeRowWithColumns(target, `tmember-${i}`, colSpecs,
            `borderOneSolid me-3 ms-1 ${stripeClass}`);
    }
}

function setupClusterGraphTextFlips() {
    $('.goToGraphCgA').on("click", showClusterAsGraph);
    $('.goToTextCgA').on("click", showClusterAsText);
}
function showClusterAsText() {
    showAndHideClasses('cgText', 'cgGraph');
}
function showClusterAsGraph() {
    showAndHideClasses('cgGraph', 'cgText');
}
