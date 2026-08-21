/*

 Copyright (c) 2008-2021 by the President and Fellows of Harvard College. All rights reserved.
 Profiles Research Networking Software was developed under the supervision of Griffin M Weber, MD, PhD.,
 and Harvard Catalyst: The Harvard Clinical and Translational Science Center, with support from the
 National Center for Research Resources and Harvard University.


 Code licensed under a BSD License.
 For details, see: LICENSE.txt

 HTML5/d3-Based Network Visualizer

 Author(s): Nick Benik

 */

network_browser = {
    _clusterEngine_ref: false,
    over_node: false,
    over_edge: false,
    _cfg: {
        height: 485,
        width: 964,
        targetEl: false,
        baseURL: false
    },
    Init: function (endpoint_URL, elSelector,modal_obj) {
        if (!endpoint_URL) endpoint_URL = '';
        let el = document.querySelector(elSelector);
        if (el === null) return false;
        network_browser._cfg.elSelector = elSelector;
        network_browser._cfg.modal_obj = modal_obj;
        network_browser._cfg.targetEl = el;
        network_browser._cfg.baseURL = endpoint_URL;
        if (network_browser._clusterEngine_ref === false) {
            network_browser._clusterEngine_ref = GenClusterView;
            network_browser._clusterEngine_ref.Init(network_browser._cfg.width, network_browser._cfg.height, network_browser._cfg.elSelector);
        }
        network_browser._clusterEngine_ref.registerCallback(network_browser._EventHandler);
    },
    render: function (renderSettings, includeLegend) {
        // network_browser.settings = renderSettings;
        // if (network_browser._cfg.modal_obj)
        //     $(network_browser._cfg.modal_obj).show();

        // extract the list IDs from the settings
        // const idList = renderSettings.map((e) => {
        //     let ret = "" + e.ListID;
        //     switch(e.GroupingLevel) {
        //         case "Person":
        //             ret += "p";
        //             break;
        //         case "Department":
        //             ret += "d";
        //             break;
        //         case "Institution":
        //             ret += "i";
        //             break;
        //     }
        //     let conns = 0;
        //     if (e.ExternalConnection === true) conns += 1;
        //     if (e.InternalConnection === true) conns += 2;
        //     ret += (""+conns);
        //     return ret;
        // }).join(',');
        // create the groups nodes from the render settings
        const extractedGroups = renderSettings.map((e) => { return {name: e.ListName, fill: e.GraphColor, border:"#999999"} });


        // dynamically add the styling elements if it does not already exist
        // =============================================================================================================
        // if (!network_browser.styleSheet) {
        //     let injectedSS = document.createElement("style");
        //     network_browser.styleSheet = injectedSS;
        //     document.head.appendChild(injectedSS);
        //     injectedSS.sheet.insertRule(`
        //     ${network_browser._cfg.elSelector} svg .gnode {
        //         cursor: move;
        //         font-family: sans-serif;
        //         font-size: 10px
        //     }`);
        //     injectedSS.sheet.insertRule(`
        //     ${network_browser._cfg.elSelector} svg .base {
        //         stroke: #000;
        //         stroke-width: 1px
        //         fill-opacity: 0.5;
        //     }`);
        //     injectedSS.sheet.insertRule(`
        //     ${network_browser._cfg.elSelector} svg .edge {
        //         stroke: rgb(187, 187, 187);
        //         stroke-opacity: 0.45;
        //     }`);
        // }



        // TODO: make call to the backend service
        // $.ajax({
        //     url: network_browser._cfg.baseURL + idList,
        //     success: function(results) {
                // genarate the data format used for render
        let results = gLists.vizClusterData;
                let renderData = {
                    Groups: extractedGroups,
//                    Groups: results.Groups,
                    Nodes: [],
                    Edges: []
                };

                // get value ranges
                var tSharedPubs = {
                    min: Math.min(...results.Edges.map((edge) => edge.n)),
                    max: Math.max(...results.Edges.map((edge) => edge.n))
                }
                var tPubs = {
                    min: Math.min(...results.Nodes.map((node) => node.pubs)),
                    max: Math.max(...results.Nodes.map((node) => node.pubs))
                }

                renderData.Nodes = results.Nodes.map((node) => {return {
                    id:node.id,
                    url: node.uri,
                    groups:node.grp,
                    radius: (5 + (node.pubs - tPubs.min + 0.1) / (tPubs.max - tPubs.min + 0.1) * 12).toFixed(3),
                    label: node.label ? node.label : node.ln + " " + node.fn.substring(0, 1),
                    tooltip: node.tooltip ? node.tooltip : node.fn + " " + node.ln,
                    description: node.description ? node.description : node.fn + " " + node.ln + " (" + node.pubs + " publication" + (node.pubs == 1 ? ")" : "s)")
                }});

                renderData.Edges = results.Edges.map((edge) => {return {
                    source:edge.source,
                    target:edge.target,
                    width: (1 + (edge.n - tSharedPubs.min + 0.1) / (tSharedPubs.max - tSharedPubs.min + 0.1) * 9).toFixed(3),
                    description: edge.description ? edge.description : renderData.Nodes[edge.source].tooltip + " / " + renderData.Nodes[edge.target].tooltip + " (" + edge.n + (edge.n == 1 ? " shared publication)" : " shared publications)"),
                }});

                // send the data to the visualization for display
                network_browser._clusterEngine_ref.render(renderData);

                if (network_browser._cfg.modal_obj)
                    $(network_browser._cfg.modal_obj).hide();

                if (includeLegend) {
                    // display the legend if needed
                    let rowHeight = 16;
                    let rowCount = renderData.Groups.length;
                    let rowPadding = 2;
                    let yOffset = network_browser._cfg.height + rowHeight;
                    let colWidthPxls = rowHeight / 2;
                    const svgRef = network_browser._clusterEngine_ref.data.d3_svg[0][0];

                    // resize the SVG to put the legend on the bottom
                    $(svgRef).attr("height", network_browser._cfg.height + (rowCount * rowHeight));
                    // loop through the lists
                    const svgns = "http://www.w3.org/2000/svg";
                    const boxSize = rowHeight - (2 * rowPadding);
                    extractedGroups.forEach((listEntry, idx) => {
                        let rowPx = idx * rowHeight - rowPadding;
                        // make a simple rectangle
                        let newRect = document.createElementNS(svgns, "rect");
                        newRect.setAttribute("x", colWidthPxls);
                        newRect.setAttribute("y", yOffset + rowPx - boxSize);
                        newRect.setAttribute("width", boxSize);
                        newRect.setAttribute("height", boxSize);
                        newRect.setAttribute("fill", listEntry.fill);
                        svgRef.appendChild(newRect);
                        // add text label
                        let txtLabel = document.createElementNS(svgns, "text");
                        txtLabel.setAttribute("x", colWidthPxls + (2 * boxSize));
                        txtLabel.setAttribute("y", yOffset + rowPx);
                        txtLabel.setAttribute("style", "font-size:" + rowHeight + "px; font-family: sans-serif;");
                        txtLabel.textContent = listEntry.name;
                        svgRef.appendChild(txtLabel);


                    });
                }
            // }
        //     ,
        //     error: function() {
        //         alert("An error occured while communicating with the server!");
        //     }
        // });
    },
    _EventHandler: function (eventName, dataObject) {
        switch (eventName) {
            case "NODE_ALT_CLICK":
                if (dataObject.url) { window.open(dataObject.url, "_blank");}
                GenClusterView.data.active = true;
                GenClusterView._eventRouter_mouseout(dataObject);
                break;            
            case "NODE_SHIFT_CLICK":            
            case "NODE_IN":
                // document.getElementById("person_name").innerHTML = dataObject.description;
                break;
            case "NODE_OUT":
                // document.getElementById("person_name").innerHTML = "";


                break;
            case "EDGE_IN":
            case "EDGE_CLICK":
            case "EDGE_SHIFT_CLICK":
                // document.getElementById("person_name").innerHTML = dataObject.infoText;
                break;
            case "EDGE_OUT":


                // document.getElementById("person_name").innerHTML = "";
                break;
            case "NETWORK_LOADED":
                break;
            default:
                break;
            // unremark these lines to see what other events can be handled
            //				alert(eventName+" is unhandled.");
            //				debugger;
        }
    }
};