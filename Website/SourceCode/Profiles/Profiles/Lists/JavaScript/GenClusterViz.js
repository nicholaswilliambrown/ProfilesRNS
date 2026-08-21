/*
 ----==================================================----
 Cluster Network Viewer - Javascript Engine
 ----==================================================----

 Events issued to the javascript callback by the Network Browser flash control
 ----------------------------------------------------
 NODE_CLICK			- user clicked the node / control recenters graph
 NODE_SHIFT_CLICK	- user shift clicked the node when the control is configured to disallow selections
 NODE_SELECTED		- user shift clicked the node when the control is configured to allow selections
 NODE_DESELECTED		- user shift clicked the node when the control is configured to allow selections
 NODE_IN				- mouse cursor has entered the node
 NODE_OUT			- mouse cursor has exited the node
 EDGE_IN				- mouse cursor has entered the edge
 EDGE_OUT			- mouse cursor has exited the edge
 EDGE_CLICK			- user clicked the edge
 EDGE_SHIFT_CLICK	- user shift clicked the edge when the control is configured to disallow selections
 EDGE_SELECTED		- user shift clicked the edge when the control is configured to allow selections
 EDGE_DESELECTED		- user shift clicked the edge when the control is configured to allow selections

 */


GenClusterView = {
    cfg: {
        width: 880,
        height: 685,
        svg_container: false,
        forces: {
            charge: -750, // Smaller charge, more repulsion.
            gravity: 0.8, // More gravity, stronger pull towards center.
            linkDist: 50		// Larger distance, more spread out.
        },
        callback: false
    },
    data: {
        active: true,
        border_color: "#BBB",
        nodes: [],
        edges: [],
        adjacency: [],
        d3_force: false,
        d3_svg: false
    },
    // =========================== PUBLIC FUNCTION ===========================
    Init: function (width, height, targetElementSelector) {
        // save info
        GenClusterView.cfg.width = width;
        GenClusterView.cfg.height = height;
        let targetElement = document.querySelector(targetElementSelector);
        GenClusterView.cfg.style_prefix = targetElementSelector + " svg";
        GenClusterView.cfg.svg_container = targetElement;
        GenClusterView.data.colors_fill = [];
        GenClusterView.data.colors_border = [];
        // create force engine
        var force = GenClusterView.cfg.forces;
        GenClusterView.data.d3_force = d3.layout.force()
            .charge(force.charge)
            .gravity(force.gravity)
            .linkDistance(force.linkDist)
            .size([width, height]);
        // create display element for the graph
        GenClusterView.data.d3_svg = d3.select(targetElement).append("svg")
            .attr("xmlns", "http://www.w3.org/2000/svg")
            .attr("width", width)
            .attr("height", height);
    },
    // =========================== PRIVATE FUNCTION ===========================
    _materializeSvgStyles: function(svgEl) {
        // need to get styles of classes that are defined in other style scripts and we need to inject that into a
        // new svg document and then save that document (with the materialized styles)

        function getStyle(className) {
            for (var cssFile=0; cssFile < document.styleSheets.length; cssFile++) {
                try {
                    var classes = document.styleSheets[cssFile].rules || document.styleSheets[cssFile].cssRules
                    for(var x=0;x<classes.length;x++) {
                        if(classes[x].selectorText==className) {
                            // build the style string
                            return classes[x].style;
                        }
                    }
                } catch(e) {}
            }
        }

        // Need to copy the styles from the class definition to the node's style attribute
        // 1) get a list of all classses found in the SVG
        var targetClasses = {};
        svgEl.querySelectorAll('*[class]').forEach((node)=>{
            for(var [i, className] of node.classList.entries()) {
                targetClasses[className] = true;
            }
        });
        // 2) get the style definitions for each class
        for (var className in targetClasses) {
            targetClasses[className] = getStyle(GenClusterView.cfg.style_prefix + ' .' + className);
        }
        // 3) replace all classes with their style definitions in a non-overriding manner
        svgEl.querySelectorAll('*[class]').forEach((node)=>{
            // for each class copy its style definition to the node
            for(var [i, className] of node.classList.entries()) {
                var targetClassDef = targetClasses[className];
                for (var styleIdx = 0; styleIdx < targetClassDef.length; styleIdx++) {
                    var styleName = targetClassDef[styleIdx];
                    if (!node.style[styleName]) {
                        node.style[styleName] = targetClassDef[styleName];
                    }
                }
            }
        });
    },
    // =========================== PUBLIC FUNCTION ===========================
    save: function () {
        const svgEl = GenClusterView.data.d3_svg[0][0];
        // materialize the CSS styles into SVG elements
        GenClusterView._materializeSvgStyles(svgEl);

        const svg = (new XMLSerializer()).serializeToString(svgEl);
        const element = document.createElement('a');
        const mimeType = 'image/svg+xml'; // 'image/svg+xml;utf8';
        const blob = new Blob([svg.toString()]);
        element.style.display = "none";
        element.href = window.URL.createObjectURL(blob);
        element.target = '_blank';
        element.mimeType = mimeType;
        element.download = 'cluster-view.svg';
        element.id = 'downloader';
        document.body.appendChild(element);
        element.click();
        element.remove();
    },
    // =========================== PUBLIC FUNCTION ===========================
    saveImg: function (scale) {
        const svg = GenClusterView.data.d3_svg[0][0];
        // materialize the CSS styles into SVG elements
        GenClusterView._materializeSvgStyles(svg);

        if (!scale) { scale = 2; }

        const origWidth = svg.width.baseVal.value;
        const origHeight = svg.height.baseVal.value;
        const canvas = document.createElement('canvas');
        canvas.style.width = origWidth;
        canvas.style.height = origHeight;
        const ctx = canvas.getContext('2d');
        ctx.canvas.width = origWidth * scale;
        ctx.canvas.height = origWidth * scale;

        const data = (new XMLSerializer()).serializeToString(svg);
        const DOMURL = window.URL || window.webkitURL || window;

        function triggerDownload (imgURI) {
            let evt = new MouseEvent('click', {
                view: window,
                bubbles: false,
                cancelable: true
            });
            const a = document.createElement('a');
            a.setAttribute('download', 'cluster-view.png');
            a.setAttribute('href', imgURI);
            a.setAttribute('target', '_blank');
            a.dispatchEvent(evt);
        }

        const img = new Image();
        const svgBlob = new Blob([data], {type: 'image/svg+xml;charset=utf-8'});
        const url = DOMURL.createObjectURL(svgBlob);
        img.onload = function () {
            ctx.drawImage(img, 0, 0, this.width * scale, this.height * scale);
            DOMURL.revokeObjectURL(url);

            const imgURI = canvas
                .toDataURL('image/png')
                .replace('image/png', 'image/octet-stream');
            triggerDownload(imgURI);
        };
        img.src = url;
    },
    // =========================== PUBLIC FUNCTION ===========================
    render: function (renderData) {
        GenClusterView.origData = renderData;

        // handle the color groups
        let groupDomain = Array.apply(null,{length:renderData.Groups.length}).map(eval.call, Number);
        let groupFillColors = renderData.Groups.map((group) => { return d3.rgb(group.fill)});
        let groupBorderColors = renderData.Groups.map((group) => { return d3.rgb(group.border)});
        GenClusterView.data.colors_fill = d3.scale.ordinal().domain(groupDomain).range(groupFillColors);
        GenClusterView.data.colors_border = d3.scale.ordinal().domain(groupDomain).range(groupBorderColors);

        // save nodes and edges
        GenClusterView.data.nodes = renderData.Nodes;
        GenClusterView.data.edges = renderData.Edges;

        // at this point the graph should already be initialized so just start the animation
        GenClusterView.data.d3_force
            .nodes(GenClusterView.data.nodes)
            .links(GenClusterView.data.edges)
            .start();

        // < Draw the visualization elements >

        // clear out the SVG so we can perform re-render if needed
        GenClusterView.data.d3_svg[0][0].innerHTML = "";

        // draw the links
        GenClusterView.data.d3_svg.selectAll(".edge")
            .data(GenClusterView.data.edges)
            .enter()
            .append("line")
            .attr("class", "edge")
            .style("stroke-width", (d) => d.width);

        // add the node groups
        let gnodes = GenClusterView.data.d3_svg.selectAll("g.gnode")
            .data(GenClusterView.data.nodes)
            .enter()
            .append('g')
            .classed('gnode', true)
            .attr('id', (d) => d.id)
            .on("dblclick", (d) => { window.open(d.url, "_blank"); })
            .call(GenClusterView.data.d3_force.drag);

        // Add a tooltip to each node group
        gnodes.append("title").text((d) => d.tooltip);

        // Pie chart coloring for each node
        gnodes.each((node, idx) => {
            let pieData = d3.layout.pie().value(() => 1)(node.groups);
            let arcGen = d3.svg.arc()
                .innerRadius(0)
                .outerRadius(parseFloat(node.radius));

            d3.select(gnodes[0][idx])
                .selectAll("path")
                .data(pieData)
                .enter()
                .append("path")
                .attr("fill", (arcData) => GenClusterView.data.colors_fill(arcData.data))
                .attr("d", (arcData) => arcGen(arcData));

        });

        // Add a circle to each node group (used by highlighting system)
        gnodes.append("circle")
            .attr("class", "base")
            .attr("r", (d) => d.radius)
            .style("stroke", GenClusterView.data.border_color)
            .style("fill-opacity", 0);


        // Add a label to each node group.
        gnodes.append("text")
            .text((d) => d.label)
            .attr("dy", "3px")
            .attr("text-anchor", "middle");

        // </ Draw the visualization elements >

        // generate an "Adjacency matrix"
        GenClusterView.data.adjacency = [];
        GenClusterView.data.edges.forEach(function (d) {
            GenClusterView.data.adjacency[d.source.index + ',' + d.target.index] = 1;
            GenClusterView.data.adjacency[d.target.index + ',' + d.source.index] = 1;
            GenClusterView.data.adjacency[d.source.index + ',' + d.source.index] = 1;
            GenClusterView.data.adjacency[d.target.index + ',' + d.target.index] = 1;
        });
        // handle nodes that do not have any connections
        GenClusterView.data.nodes.forEach(function (d) {
            GenClusterView.data.adjacency[d.index + ',' + d.index] = 1;
        });

        // connect event handler (for force graph)
        GenClusterView.data.d3_force.on("tick", GenClusterView._force_tick);
        GenClusterView.data.d3_force.drag().on("dragstart", GenClusterView._eventRouter_dragstart);


        // connect event handler (for nodes)
        GenClusterView.data.d3_svg.selectAll("g.gnode")
            .on("mouseover", GenClusterView._eventRouter_mouseover)
            .on("mouseout", GenClusterView._eventRouter_mouseout)
            .on("mousedown", GenClusterView._eventRouter_mousedown);

        // connect event handler (for links)
        GenClusterView.data.d3_svg.selectAll(".edge")
            .on("mouseover", GenClusterView._eventRouter_mouseover)
            .on("mouseout", GenClusterView._eventRouter_mouseout)
            .on("mousedown", GenClusterView._eventRouter_mousedown);


        // ++++ SEND EVENT SIGNAL TO USER CALLBACK FOR ADDITIONAL FUNCTIONALITY AND PROPER SEPARATION OF CODE ++++
        if (GenClusterView.cfg.callback !== false) {
            GenClusterView.cfg.callback.call(GenClusterView.cfg.callback, "NETWORK_LOADED", true);
        }

        // make sure that the SVG is attached to the DOM (used when re-rendering)
        GenClusterView.cfg.svg_container.appendChild(GenClusterView.data.d3_svg[0][0]);
    },
    // =========================== PUBLIC FUNCTION ===========================
    registerCallback: function (callbackRef) {
        if (typeof callbackRef === 'string') {
            alert('The HTML5 visualization requires that the [registerCallback] function receive the callback function as a reference not a string!');
            return false;
        }
        GenClusterView.cfg.callback = callbackRef;
    },
    // =========================== PRIVATE FUNCTION ===========================
    _GetGraphElementType: function (a) {
        if (typeof a.source === 'undefined') {
            return "NODE";
        } else {
            return "EDGE";
        }
    },
    // =========================== PRIVATE FUNCTION ===========================
    _neighboring: function (a, b) {
        return GenClusterView.data.adjacency[a.index + ',' + b.index];
    },
    // =========================== PRIVATE FUNCTION ===========================
    _force_tick: function () {
        if (GenClusterView.data.active === false) { return; }
        // update link positions
        GenClusterView.data.d3_svg.selectAll('.edge')
            .attr("x1", function (d) { return Math.max(Math.min(d.source.x, GenClusterView.cfg.width - 50), 50).toFixed(4); })
            .attr("y1", function (d) { return Math.max(Math.min(d.source.y, GenClusterView.cfg.height - 20), 20).toFixed(4); })
            .attr("x2", function (d) { return Math.max(Math.min(d.target.x, GenClusterView.cfg.width - 50), 50).toFixed(4); })
            .attr("y2", function (d) { return Math.max(Math.min(d.target.y, GenClusterView.cfg.height - 20), 20).toFixed(4); });
        // update node positions (specialized to force circlular orbits)
        GenClusterView.data.d3_svg.selectAll('g.gnode')
            .attr("transform", function (d) {
                return 'translate(' + [Math.max(Math.min(d.x, GenClusterView.cfg.width - 50), 50).toFixed(4), Math.max(Math.min(d.y, GenClusterView.cfg.height - 20).toFixed(4), 20)] + ')';
            });
    },
    // =========================== PRIVATE FUNCTION (INTERACTION EVENT HANDLERS) ===========================
    _extractKeys: function (mouseEvent) {
        var temp = [];
        if (mouseEvent.shiftKey) { temp.push("SHIFT"); }
        if (mouseEvent.altKey) { temp.push("ALT"); }
        if (mouseEvent.ctrlKey) { temp.push("CTRL"); }
        temp = temp.join("_");
        return { alt: mouseEvent.altKey, ctrl: mouseEvent.ctrlKey, shift: mouseEvent.shiftKey, keyString: temp };
    },
    _eventRouter_dragstart: function (a) {
        GenClusterView._mouse_events.call(GenClusterView, "dragstart", GenClusterView._extractKeys(d3.event.sourceEvent), a, this);
    },
    _eventRouter_mouseover: function (a) {
        GenClusterView._mouse_events.call(GenClusterView, "mouseover", GenClusterView._extractKeys(d3.event), a, this);
    },
    _eventRouter_mouseout: function (a) {
        GenClusterView._mouse_events.call(GenClusterView, "mouseout", GenClusterView._extractKeys(d3.event), a, this);
    },
    _eventRouter_mousedown: function (a) {
        GenClusterView._mouse_events.call(GenClusterView, "mousedown", GenClusterView._extractKeys(d3.event), a, this);
    },
    _mouse_events: function (eventname, keys, obj, el) {
        // ++++ MAIN EVENT HANDLER ++++
        // build the event string
        var externEventName = [GenClusterView._GetGraphElementType(obj)];
        if (keys.keyString.length > 0) { externEventName.push(keys.keyString); }
        switch (eventname) {
            case 'mousedown':
                externEventName = externEventName.join("_") + "_CLICK";
                break;
            case 'mouseover':
                externEventName = externEventName.join("_") + "_IN";
                break;
            case 'mouseout':
                externEventName = externEventName.join("_") + "_OUT";
                break;
            case 'dragstart':
                externEventName = externEventName.join("_") + "_DRAGSTART";
                break;
            //            default:
            //                console.warn('got event [' + eventname + ']');
            //                break;
        }
        // now do any local GUI processing based on the event string value
        switch (externEventName) {
            case "NODE_IN":          
            case "NODE_ALT_IN":
            case "NODE_SHIFT_IN":
                GenClusterView.data.d3_svg.selectAll(".edge")
                    .style('stroke', function (l) { return (obj === l.source || obj === l.target) ? '#F00' : '#BBB'; })
                    .style('stroke-opacity', function (l) { return (obj === l.source || obj === l.target) ? 1 : 0.45; });
                GenClusterView.data.d3_svg.selectAll("g.gnode circle.base")
                    .style('stroke', function (d) { return GenClusterView._neighboring(d, obj) ? '#F00' : GenClusterView.data.border_color; })
                    .style('stroke-width', function (d) { return GenClusterView._neighboring(d, obj) ? '2px' : '1px'; });
                break;
            case "NODE_OUT":
            case "EDGE_OUT":            
            case "NODE_ALT_OUT":
            case "EDGE_ALT_OUT":
            case "NODE_SHIFT_OUT":
            case "EDGE_SHIFT_OUT":
                GenClusterView.data.d3_svg.selectAll("g.gnode circle.base")
                    .style('stroke', GenClusterView.data.border_color)
                    .style('stroke-width', '1px');
                GenClusterView.data.d3_svg.selectAll(".edge")
                    .style('stroke', '#BBB')
                    .style('stroke-opacity', 0.45);
                break;
            case "EDGE_IN":           
            case "EDGE_ALT_IN":
            case "EDGE_SHIFT_IN":
            case "EDGE_CLICK":
                // highlight link
                d3.select(el)
                    .style('stroke', '#F00')
                    .style('stroke-opacity', 1);
                // highlight the two nodes
                d3.select($("#" + obj.target.id)[0]).selectAll('circle.base')
                    .style('stroke', '#F00')
                    .style('stroke-width', '2px');
                d3.select($("#" + obj.source.id)[0]).selectAll('circle.base')
                    .style('stroke', '#F00')
                    .style('stroke-width', '2px');
                break;
            case "NODE_CLICK":
            case "NODE_DRAGSTART":
            case "NODE_SHIFT_DRAGSTART":
                if (keys.shift === true) {
                    obj.fixed |= 0x08;
                } else {
                    obj.fixed &= ~0x08;
                }
                break;        
            case "NODE_ALT_CLICK":
                // stop the visualization in preparation of page naviation
                GenClusterView.data.active = false;
                break;
                        default:
            //                alert(externEventName);
                            break;
        }

        //		console.warn(externEventName);
        // ++++ SEND EVENT SIGNAL TO USER CALLBACK FOR ADDITIONAL FUNCTIONALITY AND PROPER SEPARATION OF CODE ++++
        if (GenClusterView.cfg.callback !== false) {
            GenClusterView.cfg.callback(externEventName, obj);
        }
    }
}