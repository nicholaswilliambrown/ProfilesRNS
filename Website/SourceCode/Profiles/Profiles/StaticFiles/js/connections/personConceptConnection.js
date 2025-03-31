async function setupConceptConnection() {
    await commonSetup();
    setTabTitleAndOrFavicon("Connection");

    setupScrolling();

    captchavate(async function() {
        let [jsonArray] = await setupJson();
        mainParse(jsonArray[0].ModuleData);
    });
}
function mainParse(data) {
    let topLhsDiv = $('#topLhsDiv');
    innerCurtainsDown(topLhsDiv);

    let target = createOrGetTopLhsDiv();
    let name = data.Name;
    let concept = data.Concept;
    let backUrl = data.BackToURL;

    emitConnectionTopStuff(
        {
            target:         target,
            displayName:    data.DisplayName,
            text1:          name,
            url1:           data.PersonURL,
            text2:          concept,
            url2:           data.ConceptURL,
            weight:         data.Weight,
            subtitle:       'Concept',
            backUrl:        backUrl,
            lhsBlurb:       `This page shows the publications ${name} 
                                has written about ${concept}.`
        });

    conceptConnectionParser(target, data);

    innerCurtainsUp(topLhsDiv);
}
function conceptConnectionParser(target, data) {

    let list = $('<ol></ol>');
    target.append(list);

    let pubs = reverseSortArrayByWeight(data.Publications);
    for (let i=0; i<pubs.length; i++) {
        let pub = pubs[i];

        let item = $(`<li></li>`);
        list.append(item);

        let referenceDiv = $(`<div class="mt-2">${pub.Reference}</div>`);
        let pubMedUrlDiv = $(`<div>View in </div>`);
        let pubMedUrl = createAnchorElement(
            'PubMed',
            gConnections.pubMedUrlSchema.replace(gCommon.schemaPlaceholder, pub.PMID));
        pubMedUrlDiv.append(pubMedUrl);
        let scoreDiv = $(`<div class="mb-1">Score: ${pub.Weight}</div>`);

        if (i>0) {
            item.append($('<hr class="tightHr"/>'));
        }
        item.append(referenceDiv).append(pubMedUrlDiv).append(scoreDiv);

        hoverLight(item);
    }
}

