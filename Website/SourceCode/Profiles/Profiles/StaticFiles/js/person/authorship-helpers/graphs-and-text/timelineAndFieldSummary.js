async function authNavGreenField(e, options) {
    let overallDivId = options.overallDivId;
    let toTextId     = options.toTextId    ;
    let toGraphId    = options.toGraphId   ;
    let theText      = options.theText        ;
    let graphId      = options.graphId     ;
    let graphFn      = options.graphFn     ;
    let addTextFn    = options.addTextFn   ;

    authNavAdjustStyle(e);
    gPerson.authorshipInnerDiv.empty();

    let overallDiv = $(`<div id="${overallDivId}"></div>`);
    gPerson.authorshipInnerDiv.append(overallDiv);

    let aClickToText = $('<a class="link-ish toggleGraphLink mb-2" id="${toTextId}">click here</a>');
    let aClickToGraph = $('<a class="link-ish toggleGraphLink mb-2" id="${toGraphId}">click here</a>');

    let mainText = theText;
    let overallDivToTextDiv = $(`<div class="mt-2">${mainText} To see the data as text, </div>`);
    let overallDivToGraphDiv = $(`<div class="mt-2">${mainText} To return to the graph, </div>`);

    overallDivToTextDiv.append(aClickToText).append($('<span class="mb-4">.</span>'));
    overallDivToGraphDiv.append(aClickToGraph).append($('<span class="mb-4">.</span>'));

    let graphDiv = $(`<div class="forGraph mt-3 ${graphId}" id="${graphId}"></div>`);
    overallDivToTextDiv.append(graphDiv);
    overallDivToTextDiv.append($(`<div id="${graphId}-alt"></div>`));

    addTextFn(overallDivToGraphDiv);

    overallDiv.append(overallDivToTextDiv);
    overallDiv.append(overallDivToGraphDiv);

    overallDivToGraphDiv.hide();

    aClickToText.on('click', async function() {
        overallDivToTextDiv.hide();
        overallDivToGraphDiv.show();

    });
    aClickToGraph.on('click', function() {
        overallDivToGraphDiv.hide();
        overallDivToTextDiv.show();
    });

    overallDivToGraphDiv.hide();

    graphFn(graphDiv);
}
function authNavTimeline(e) {
    authNavGreenField(e, {
        "overallDivId": "authTimelineDiv",
        "toTextId":     "toTimelineText",
        "toGraphId":    "toTimelineGraph",
        "theText":      "This graph shows the total number of publications by year. ",
        "graphId":      "timelineGraphDiv",
        "graphFn":      populateAuthorTimelineGraph,
        "addTextFn":    authAddTextForTimeline
    });
}
function authNavFieldSummary(e) {
    authNavGreenField(e, {
        "overallDivId": "authFieldSummaryDiv",
        "toTextId":     "toFieldSummaryText",
        "toGraphId":    "toFieldSummaryGraph",
        "theText":      `This graph shows the number and percent of publications by field. Fields are based on how the National Library of Medicine (NLM) classifies the publications' journals and might not represent the specific topics of the publications. Note that an individual publication can be assigned to more than one field. As a result, the publication counts in this graph might add up to more than the number of publications the person has written. `,
        "graphId":      "fieldSummaryGraphDiv",
        "graphFn":      populateFieldSummaryGraph,
        "addTextFn":    authAddTextForFieldSummary
    });
}
