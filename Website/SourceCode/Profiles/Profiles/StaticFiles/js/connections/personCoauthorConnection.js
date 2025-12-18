async function setupCoauthorConnection() {
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
    let name2 = data.Name2;
    let backUrl = data.BackToURL;

    let backLabel;
    let coathInfo = fromSession(gCoauthor.whichTabKey);
    if (coathInfo) {
        backLabel = coathInfo.label;
        backUrl = coathInfo.url;
    }

    emitConnectionTopStuff(
        {
            target:         target,
            displayName:    name,
            text1:          name,
            url1:           data.PersonURL,
            text2:          name2,
            url2:           data.PersonURL2,
            weight:         data.Weight,
            subtitle:       'Co-Author',
            backUrl:        backUrl,
            backLabel:      backLabel,
            lhsBlurb:       `This page shows the publications co-authored by ${name} and ${name2}.`
        });

    coauthConnectionParser(target, data);

    innerCurtainsUp(topLhsDiv);
}
function coauthConnectionParser(target, data) {

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

