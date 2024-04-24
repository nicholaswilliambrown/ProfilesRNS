async function clusterParse(moduleJson) {

    $('.personDisplayName').html(getPersonFirstLastName());

    // add wide and narrow cluster options
    $("#wideClusterGraph").addClass(gCommon.hideXsShowOthers);
    $("#narrowClusterGraph").addClass(`${gCommon.showXsHideOthers} mlMuch`);

    let jsonData = moduleJson.ModuleData[0];

    displayClusterTab(jsonData);

    $(window).resize(function(){
        displayClusterTab(jsonData);
    });
}
function displayClusterTab(jsonData) {
    $('.clusterView').empty();

    let jsonCopy = JSON.parse(JSON.stringify(jsonData));
    emitClusterGraph(jsonCopy);
    emitClusterText(jsonCopy, $('#cgTextDiv'));

    setupClusterGraphTextFlips();
    showClusterAsGraph();
}
function emitClusterText(jsonData, target) {
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
        .filter(coConn =>   coConn.id1 != gCoauthor.personId &&
            coConn.id2 != gCoauthor.personId);

    emitTextCoauthors(target, coauthors, fullConnections);
    emitTextCoauthorsOfCoauthors(target, coauthorsOfCoauthors);
    emitTextCoauthorsConnections(target, coauthorsConnections, networkPeople);
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
