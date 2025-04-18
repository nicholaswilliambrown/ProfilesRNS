async function setupSimilarConnection() {
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
    let name1 = data.Name;
    let name2 = data.Name2;
    let backUrl = data.BackToURL;

    emitConnectionTopStuff(
        {
        target:         target,
        displayName:    data.DisplayName,
        text1:          name1,
        url1:           data.PersonURL,
        text2:          name2,
        url2:           data.PersonURL2,
        weight:         data.Weight,
        subtitle:       'Similar Person',
            backUrl:        backUrl,
            lhsBlurb:      `This page shows the concepts shared by 
                                    ${name1} and ${name2}.`
        });
    personConnectionParser(target, data)

    innerCurtainsUp(topLhsDiv);
}
function personConnectionParser(target, data) {

    // todo: networkPath should prob have 'Network/', not 'Concept/'
    let shortNetworkPath = data.NetworkPath.replace("Concept/", "Network/");

    let person1ConceptUrlPrefix = `${data.PersonURL}${shortNetworkPath}`;
    let person2ConceptUrlPrefix = `${data.PersonURL2}${shortNetworkPath}`;

    let colspecs = [
        newColumnSpec(`${gCommon.cols5or12} bordE `),
        newColumnSpec(`${gCommon.cols3or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols3or12} bordE  t-center`),
        newColumnSpec(`${gCommon.cols1or12} pe-0 `)
    ];

    let rowId = `connections`;
    let row = makeRowWithColumns(target, rowId, colspecs, "borderOneSolid stripe mt-2");

    row.find(`#${rowId}Col0`).html('<strong>Concept</strong>').addClass("pt-1");
    row.find(`#${rowId}Col1`).html(`<strong>${data.Name}</strong>`).addClass("pt-1");
    row.find(`#${rowId}Col2`).html(`<strong>${data.Name2}</strong>`).addClass("pt-1");
    row.find(`#${rowId}Col3`).html('<strong>Score</strong>').addClass("pt-1");

    let concepts = sortArrayViaSortLabel(data.Concepts, 'Score', true);
    for (let i=0; i<concepts.length; i++) {
        let conn = concepts[i];
        let stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";

        let conceptPath = conn.ConceptPath;
        let conceptShortPath = conceptPath.replace("display/", "");
        let person1ConceptAnchor = createAnchorElement(
            conn.Person1Weight, undoubleTheSlash(person1ConceptUrlPrefix + conceptShortPath));
        let person2ConceptAnchor = createAnchorElement(
            conn.Person2Weight, undoubleTheSlash(person2ConceptUrlPrefix + conceptShortPath));

        let concept = conn.Concept;
        let conceptA = createAnchorElement(concept, conceptPath);
        let score = conn.Score;

        let rowId = `connections-${i}`;
        row = makeRowWithColumns(target, rowId, colspecs,
            `ms-1 borderOneSolid ${stripeClass}`);

        row.find(`#${rowId}Col0`).append(conceptA);
        row.find(`#${rowId}Col1`).append(person1ConceptAnchor);
        row.find(`#${rowId}Col2`).append(person2ConceptAnchor);
        row.find(`#${rowId}Col3`).html(score);

        hoverLight(row);
    }
    return target;
}

