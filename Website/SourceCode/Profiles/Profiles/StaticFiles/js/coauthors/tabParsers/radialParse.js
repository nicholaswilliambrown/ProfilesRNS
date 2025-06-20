async function radialParse(target, moduleJson) {

    adjustRadialView();

    $('.personDisplayName').html(getPersonFirstLastName());
    adjustRadialDiv(target);

    let jsonData = moduleJson.ModuleData[0];
    emitRadialGraph(jsonData);
    emitRadialText(jsonData);

    showRadialAsGraph();
}
function emitRadialText(jsonData) {
    emitClusterText(jsonData, $('#rgTextTarget'));
}


function emitRadialGraph(jsonData) {
    // cf. viz.js, ...prototype.loadNetwork

    try {
        let personId = getPersonId(jsonData);
        
        let radial_viz = new RadialGraph_Visualization($('#radial_view'), {radius: 85});
        radial_viz.data.center_id = personId;
        radial_viz.loadedNetwork.bind(radial_viz);
        radial_viz.loadedNetwork({}, jsonData);
    }
    catch (error) {
        console.log(error);
        $('#radialViewDiv').html("<h1>Trouble loading Radial graph</h1>");
    }
}

function makeRadialSliderColSpecs() {
    let rsCols = {};

    // numPubs
    rsCols.numPubsHeaderCS = newColumnSpec(`${gCommon.cols12} radialSliderHeader`  ,
        spanify('Minimum number of publications'));
    rsCols.numPubsSliderCS = newColumnSpec(`${gCommon.cols12}`,
        $(`<div id="copubs" class="slider">                                
                <div id="copubs_handle" class="handle"></div>
                <div class="span"></div></div>`));
    rsCols.numPubsUnderLabelCS = newColumnSpec(`${gCommon.cols12} d-flex justify-content-center`,
        spanify('any number'));

    // numCoPubs
    rsCols.numCoPubsHeaderCS = newColumnSpec(`${gCommon.cols12} radialSliderHeader`,
        spanify('Minimum number of co-publications'));
    rsCols.numCoPubsSliderCS = newColumnSpec(`${gCommon.cols12}`,
        $(`<div id="pub_cnt" class="slider">                                
                <div id="pub_cnt_handle" class="handle"></div>
                <div class="span"></div></div>`));
    rsCols.numCoPubsUnderLabelCS = newColumnSpec(`${gCommon.cols12} d-flex justify-content-center`,
        spanify('any collaboration'));

    // mrYear
    rsCols.mrYearHeaderCS = newColumnSpec(`${gCommon.cols12} radialSliderHeader`,
        spanify('Year of most recent co-publication'));
    rsCols.mrYearSliderCS = newColumnSpec(`${gCommon.cols12}`,
        $(`<div id="pub_date" class="slider">                                
                <div id="pub_date_handle" class="handle"></div>
                <div class="span"></div></div>`));
    rsCols.mrYearUnderLabelCS = newColumnSpec(`${gCommon.cols12} d-flex justify-content-center`,
        spanify('any year'));

    return rsCols;
}

function adjustRadialView() {
    let mlDiv = $('#modules-left-div');
    let viewWidth = mlDiv.width();
    let viewHeight = mlDiv.height();
    $('#radial_view').attr('viewBox', `0 0 ${viewWidth} ${viewHeight}`);
}
function adjustRadialDiv() {

    let target = $('#viz_sliders0');
    let rsCols = makeRadialSliderColSpecs();

    let numPubsGrid = radialSliderColsSubGrid("pubs",
        [   rsCols.numPubsHeaderCS,
            rsCols.numPubsSliderCS,
            rsCols.numPubsUnderLabelCS]);
    let numCoPubsGrid = radialSliderColsSubGrid("copubs",
        [   rsCols.numCoPubsHeaderCS,
            rsCols.numCoPubsSliderCS,
            rsCols.numCoPubsUnderLabelCS,]);
    let numMrYearGrid = radialSliderColsSubGrid("recent",
        [   rsCols.mrYearHeaderCS,
            rsCols.mrYearSliderCS,
            rsCols.mrYearUnderLabelCS]);

    let colSpecsOuter = [
        newColumnSpec(`${gCommon.cols4or12}`, numPubsGrid),
        newColumnSpec(`${gCommon.cols4or12}`, numCoPubsGrid),
        newColumnSpec(`${gCommon.cols4or12}`, numMrYearGrid)
    ];
    makeRowWithColumns(target, `outerSliders`,
        colSpecsOuter, `outerSliders`);
}
function radialSliderColsSubGrid(lblRowId, colSpecs) {
    let containerDiv = $(`<div class="colsSubGrid mt-3"></div>`);

    makeRowWithColumns(containerDiv, lblRowId + 0, [colSpecs[0]]);
    makeRowWithColumns(containerDiv, lblRowId + 1, [colSpecs[1]]);

    let underRowId = lblRowId + 2;
    let underRowLabelId = `${underRowId}Col0`;

    let row = makeRowWithColumns(containerDiv, underRowId, [colSpecs[2]]);
    row.find(`#${underRowLabelId}`).attr("id", `lbl_${lblRowId}`);

    return containerDiv;
}
function setupRadialGraphTextFlips() {
    $('.goToGraphRgA').on("click", showRadialAsGraph);
    $('.goToTextRgA').on("click", showRadialAsText);
}
function showRadialAsGraph() {
    showAndHideClasses('rgGraph', 'rgText');
    setupRadialGraphTextFlips();
}
function showRadialAsText() {
    showAndHideClasses('rgText', 'rgGraph');
    setupRadialGraphTextFlips();
}
