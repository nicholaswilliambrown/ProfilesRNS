
function setupForCluster(target) {
    let legendSpan = $(`
                    <span>
                    <input class="mt-1" type="CheckBox" id="chkIncludeLegand" checked="true"/>
                    <label class="form-label bold" style="position: relative; top: -1px;" for="chkIncludeLegand">
                    Include legend in graph</label>
            `);
    let safariDisabled = (!!navigator.userAgent.match(/Version\/[\d\.]+.*Safari/)) ?
                            'disabled="disabled"' : '';
    let dlSizeSelect = $(`
                <select id="download-options" class="headerColor" aria-label="Download size">
                    <option disabled selected="selected" value="">Download size</option>
                    <option ${safariDisabled} value="png-small">Small PNG</option>
                    <option ${safariDisabled} value="png-medium">Medium PNG</option>
                    <option ${safariDisabled} value="png-large">Large PNG</option>
                    <option value="svg">SVG</option>
                </select>
            `)

    let generateClusterBtn = $(`<button class="headerColor" id="btnGenerateView">Generate Cluster View</button>`);

    generateClusterBtn.on('click', async function (e) {
        dlSizeSelect.show();
        await GenGraph();
        $(e.target).html('Regenerate Cluster View');
        return false;
    });

    let colSpecs = makeColSpecsViz([
        legendSpan,
        '',
        '',
        dlSizeSelect,
        generateClusterBtn
    ], true);
    makeRowWithColumns(target, 'clusterControls', colSpecs, 'ms-0 ps-0');

    // $('.grouping-level').change(function (evt) {
    //     gLists.vizClusterData.find(el => el.ListID == $(this).attr('data-id')).GroupingLevel = $(this.options[this.selectedIndex]).val();
    // });

    $('[data-toggle="tooltip"]').tooltip();

    dlSizeSelect.change(function () {
        let value = dlSizeSelect.val();
        switch (value) {
            case "svg":
                network_browser._clusterEngine_ref.save();
                break;
            case "png-small":
                network_browser._clusterEngine_ref.saveImg(1);
                break;
            case "png-medium":
                network_browser._clusterEngine_ref.saveImg(2);
                break;
            case "png-large":
                network_browser._clusterEngine_ref.saveImg(4);
                break;
        }

        dlSizeSelect[0].selectedIndex = 0;
    });
    dlSizeSelect.hide();
}

async function GenGraph() {
    $('.modalupdate').show();
    $('#graph-render-area').empty();

    setupNetworkBrowser();
    network_browser.Init(false,'#graph-render-area', '.modalupdate');

    let listIdsCode = emitCriteriaListCode();
    gLists.vizClusterData = await createListCluster(listIdsCode);
    network_browser.render(gLists.vizClusterData, $("#chkIncludeLegand").prop("checked"));

    $('.modalupdate').hide();
}

function setupColorPicker (target, data, i) {
    target.ColorPicker({
        color: data.GraphColor,
        onShow: function (colpkr) {
            $(colpkr).fadeIn(500);
            return false;
        },
        onHide: function (colpkr) {
            $(colpkr).fadeOut(500);
            return false;
        },
        onChange: function (hsb, hex, rgb) {
            // 1. Update the outer wrapper background
            $(`#colorPicker-${i}`).css('backgroundColor', '#' + hex);

            // 2. Update the inner block background so it doesn't stay the original color
            $(`#colorPicker-${i} div`).css('backgroundColor', '#' + hex);

            gLists.vizData.find(row => row.ListID == data.ListID).GraphColor = '#' + hex;
        }
    });
    target.css('background-color', data.GraphColor);
    target.css('font-weight', 'bold');

    $('#colorSelector').ColorPicker({
        color: '#0000ff',
        onShow: function (colpkr) {
            $(colpkr).fadeIn(500);
            return false;
        },
        onHide: function (colpkr) {
            $(colpkr).fadeOut(500);
            return false;
        },
        onChange: function (hsb, hex, rgb) {
            $('#colorSelector div').css('backgroundColor', '#' + hex);
        }
    });
}
async function loadClusterHtml(target) {
    let content = $(`
        <div
        style="float: left; margin-top: 16px; width: 100%; font-size: 12px; line-height: 16px; border-bottom: 1px dotted #999; padding-bottom: 12px; margin-bottom: 10px;">
        Generate a cluster view of multiple lists to visualize co-authorships of groups of faculty. The size of a circle
        is proportional to the number of publications an author has. The thickness of a line connecting two authors'
        names is proportional to the number of publications that they share.
    </div>
    <div style="margin-bottom: 5px;"><span style="font-size: 13px; font-weight: bold;">Select Options</span></div>
    <div>
        <ul style="font-size: 12px !important;">
            <li>Group every list on a person, a department, or an institution level.</li>
            <li>Check or uncheck "<b>Internal Connections</b>" to see or hide relationships between authors of that
                list.
            </li>
            <li>Check or uncheck "<b>External Connections</b>" to see or hide relationships between authors of two
                different lists. Note that this box must be checked for both lists.
            </li>
            <li>Other options for customizing this network view are listed below the graph.</li>
        </ul>
    </div>
    <div id="list-viz-table">
        <div id="clusterCriteria" class="w-100">
        </div>
    </div>
    <div class="clusterView" id="generated-graph-area">
        <div style="display: table-row">
            <div id="graph-render-area" style="border: 1px solid gray; margin-bottom: 16px; margin-top: 16px;"></div>
        </div>
        <div style="display: table-row">
            Click and drag the name of any authors to adjust the clusters. Shift-click and drag the name of any author
            to move them and pin it to a fixed location. Click again to unlock the position. Alt-click a name to view
            what person's full profile. Please note that it might take several minutes for the clusters in this graph to
            form, and each time you view the page the graph might look slightly different.
        </div>
    </div>
    `);
    await target.append(content);
}
function setupHtml(target) {
    let clusterCriteria = target.find('#clusterCriteria');
    let colSpecs = makeColSpecsViz([
        'Person List',
        'Grouping Level',
        'Select Color',
        'Internal Connection',
        'External Connection'
    ]);

    makeRowWithColumns(clusterCriteria, 'CriteriaHeader', colSpecs, 'listsTableHeader bord9 myMs-0');

    emitCriteriaRows(clusterCriteria);

    setupForCluster(clusterCriteria);
}
function emitCriteriaRows(target) {
    for (let i=0; i<gLists.vizData.length; i++) {
        let data = gLists.vizData[i];

        let listId = data.ListID;
        let groupSelect = $(`<select class=" d-flex align-items-center groupSelect" id="groupSelect-${i}"></select>`);
        groupSelect.append($(`<option value="${listId}p" selected="true">Person</option>`));
        groupSelect.append($(`<option value="${listId}d">Department</option>`));
        groupSelect.append($(`<option value="${listId}i">Institution</option>`));

        let colorPickerOuterDiv = $(`<div class="mt-1 mb-1 myColorSelector" id="colorPicker-${i}"></div>`);
        colorPickerOuterDiv.append($(`<div></div>`));
        setupColorPicker(colorPickerOuterDiv, data, i);

        let internalCheckbox = $(`<input type="checkbox" 
                    ${data.InternalConnection ? 'checked' : ''} id="internalCheckbox-${i}">`);
        let externalCheckbox = $(`<input type="checkbox"  
                    ${data.ExternalConnection ? 'checked' : ''} id="externalCheckbox-${i}">`);

        let rowColSpecs = makeColSpecsViz([
            data.ListName,
            groupSelect,
            colorPickerOuterDiv,
            internalCheckbox,
            externalCheckbox
        ]);
        makeRowWithColumns(target, 'CriteriaRow'+i, rowColSpecs, 'odd bord9 myMs-0');
    }
}
function emitCriteriaListCode() {
    let codes = [];
    for (let i=0; i<gLists.vizData.length; i++) {
        let idAndGroup = $(`#groupSelect-${i}`).val();
        //let color = $(`#colorPicker-${i}`).css('background-color');

        let internal = $(`#internalCheckbox-${i}`).is(":checked");
        let external = $(`#externalCheckbox-${i}`).is(":checked");

        let exInCode = 0;
        if (internal && external) {
            exInCode = 3;
        }
        else if (internal) {
            exInCode = 2;
        }
        else if (external) {
            exInCode = 1;
        }

        codes.push(`${idAndGroup}${exInCode}`);
    }
    let result = codes.join(',');
    console.log('listIdsCode', result);
    return result;
}
function makeColSpecsViz(vals, noColBorders) {
    let colBorders = noColBorders ? '' : 'bordE';
    let colSpecs = [newColumnSpec(`${gCommon.cols3or12} ${colBorders} p-1 d-flex align-items-center `,                            vals[0]),
                    newColumnSpec(`${gCommon.cols2or12} ${colBorders} p-1 d-flex align-items-center justify-content-center`,   vals[1]),
                    newColumnSpec(`${gCommon.cols2or12} ${colBorders} d-flex justify-content-center`,   vals[2]),
                    newColumnSpec(`${gCommon.cols2or12} ${colBorders} p-1 d-flex justify-content-center`,   vals[3]),
                    newColumnSpec(`${gCommon.cols3or12} p-1 d-flex justify-content-center`,                 vals[4])
    ];
    return colSpecs;
}
