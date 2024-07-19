async function setupConceptConnection() {
    // only need jsonArray
    let [jsonArray] = await commonSetupWithJson();

    setupScrolling();

    mainParse(jsonArray[0].ModuleData);
}
function mainParse(data) {
    let target = createTopLhsDiv();
    let name = data.Name;
    let concept = data.Concept;

    emitConnectionTopStuff(
        {
            target:         target,
            displayName:    data.DisplayName,
            text1:          name,
            url1:           data.PersonURL,
            text2:          concept,
            url2:           data.ConceptURL,
            pid:            data.PersonID,
            weight:         data.Weight,
            lhsBlurb:       `This page shows the publications ${name} 
                                has written about ${concept}.`
        });

    conceptConnectionParser(target, data);
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

