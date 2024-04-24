/*
See networkCluster/networkBroswerClass.js
*/

let sliders = { ranges: {}, callbacks: {} };

function emitClusterGraph(jsonData) {
    let visibleCluster = $(".clusterView").filter(":visible");
    ProfilesRNS_ClusterView.Init(600, 485, visibleCluster[0]);
    ProfilesRNS_ClusterView.registerCallback(_flashEventHandler);
    ProfilesRNS_ClusterView.loadNetwork(jsonData);
}

function _flashEventHandler (eventName, dataObject) {
    switch (eventName) {
        case "NODE_ALT_CLICK":
            window.open(dataObject.uri, "_self");
            break;
        case "NODE_CTRL_CLICK":
            window.open(dataObject.uri + "/network/coauthors/cluster", "_self");
            break;
        case "NODE_CLICK":
        case "NODE_SHIFT_CLICK":
        case "NODE_SHIFT_ALT_CLICK":
        case "NODE_SHIFT_CTRL_CLICK":
        case "NODE_ALT_CTRL_CLICK":
        case "NODE_SHIFT_ALT_CTRL_CLICK":
        case "NODE_IN":
            var t = dataObject.fn + ' ' + dataObject.ln + ' (' + dataObject.pubs + ' publication';
            t += (dataObject.pubs != 1) ? 's)' : ')';
            document.getElementById("person_name").innerHTML = t;
            break;
        case "NODE_OUT":
            document.getElementById("person_name").innerHTML = "";
            break;
        case "EDGE_IN":
        case "EDGE_CLICK":
        case "EDGE_SHIFT_CLICK":
            document.getElementById("person_name").innerHTML = dataObject.infoText;
            break;
        case "EDGE_OUT":
            document.getElementById("person_name").innerHTML = "";
            break;
        case "DATA_RANGE":
            if (dataObject.invalidAttribute) {
                alert("Invalid data attribute: [" + dataObject.attribute + "]");
            } else {
                sliders.ranges[dataObject.attribute] = dataObject;
            }
            break;
        case "DUMP_NODES":
        case "DUMP_EDGES":
        case "NETWORK_LOADED":
            break;
    }
}
