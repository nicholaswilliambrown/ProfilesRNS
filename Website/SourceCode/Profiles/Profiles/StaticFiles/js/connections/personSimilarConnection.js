async function setupSimilarConnection() {
    // only need jsonArray
    let [jsonArray] = await commonSetupWithJson();

    setupScrolling();

    mainParse(jsonArray[0].ModuleData);
}
function mainParse(data) {
    let target = createTopLhsDiv();
    let name1 = data.Name;
    let name2 = data.Name2;

    emitConnectionTopStuff(
        {
        target:         target,
        displayName:    data.DisplayName,
        text1:          name1,
        url1:           data.PersonURL,
        text2:          name2,
        url2:           data.PersonURL2,
        pid:            data.PersonID,
        weight:         data.Weight,
        lhsBlurb:      `This page shows the concepts shared by 
                                    ${name1} and ${name2}.`
        });
    personConnectionParser(target, data)
}
function personConnectionParser(target, data) {

    let person1UrlPrefix = `${data.PersonURL}${data.NetworkPath}`;
    let person2UrlPrefix = `${data.PersonURL2}${data.NetworkPath}`;

    let colspecs = [
        newColumnSpec(`${gCommon.cols5or12} bordE `),
        newColumnSpec(`${gCommon.cols3or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols3or12} bordE  t-center`),
        newColumnSpec(`${gCommon.cols1or12} pe-0 `)
    ];

    let rowId = `connections`;
    let row = makeRowWithColumns(target, rowId, colspecs, "borderOneSolid stripe mt-2");

    row.find(`#${rowId}Col0`).html('<strong>Concept</strong>').addClass("pt-1");
    row.find(`#${rowId}Col1`).html('<strong>Person 1</strong>').addClass("pt-1");
    row.find(`#${rowId}Col2`).html('<strong>Person 2</strong>').addClass("pt-1");
    row.find(`#${rowId}Col3`).html('<strong>Score</strong>').addClass("pt-1");

    let concepts = sortArrayViaSortLabel(data.Concepts, 'Score', true);
    for (let i=0; i<concepts.length; i++) {
        let conn = concepts[i];
        let stripeClass = (i%2 == 1) ? "stripe" : "";

        // conceptPath in Json /* may have extra slash */
        let conceptPath = conn.ConceptPath /* .replace(/^\//, "") */ ;
        let person1Anchor = createAnchorElement(
            conn.Person1Weight, person1UrlPrefix + conceptPath);
        let person2Anchor = createAnchorElement(
            conn.Person2Weight, person2UrlPrefix + conceptPath);

        let concept = conn.Concept;
        let score = conn.Score;

        let rowId = `connections-${i}`;
        row = makeRowWithColumns(target, rowId, colspecs,
            `ms-1 borderOneSolid ${stripeClass}`);

        row.find(`#${rowId}Col0`).html(concept);
        row.find(`#${rowId}Col1`).append(person1Anchor);
        row.find(`#${rowId}Col2`).append(person2Anchor);
        row.find(`#${rowId}Col3`).html(score);

        hoverLight(row);
    }
    return target;
}

