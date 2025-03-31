function detailsParse(target, moduleJson) {

    let jsonData = moduleJson.ModuleData;

    target.append(`<div class="mt-2">${gCoauthor.coauthorsWithDash} are listed by decreasing relevence ` +
        'which is based on the number of co-publications and the years which ' +
        'they were written.</div>')
    target.append('<hr class="mt-2"/>');

    detailsParseWide(target, jsonData);
    detailsParseNarrow(target, jsonData);
}
function detailsParseWide(target, jsonData) {
    let wideDiv = $(`<div class="${gCommon.hideXsSmallShowOthers}"></div>`);
    target.append(wideDiv);

    let colspecs = [
        newColumnSpec(`${gCommon.cols5or12} bordE `),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols1or12} pe-0 `)
    ];

    let rowId = `detailsTable`;
    let row = makeRowWithColumns(wideDiv, rowId, colspecs, "borderOneSolid tableHeaderPagingRow");

    row.find(`#${rowId}Col0`).html('<strong>Name</strong>').addClass("pt-2");
    row.find(`#${rowId}Col1`).html('<strong>Most Recent Co-Publication</strong>');
    row.find(`#${rowId}Col2`).html('<strong>Number of Co-Publications</strong>');
    row.find(`#${rowId}Col3`).html('<strong>Co-Author Score</strong>').addClass("pt-2");
    row.find(`#${rowId}Col4`).html('<strong>Why?</strong>').addClass("pt-2");

    let numItems = jsonData.length;
    for (let i=0; i<numItems; i++) {
        let conn = jsonData[i];

        let stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";
        let url = conn.URL;

        let name = conn.DisplayName;
        let nameA = createAnchorElement(name, url);

        let lastPubYear = conn.LastPubYear;
        let count = conn.Count
        let weight = Number(conn.Weight).toFixed(3);

        let whyPath = conn.WhyPath;

        let whyAnchor = createAnchorElement('Why?', whyPath);

        let rowId = `details-${i}`;
        row = makeRowWithColumns(wideDiv, rowId, colspecs,
            `ms-1 borderOneSolid ${stripeClass}`);

        row.find(`#${rowId}Col0`).html(nameA);
        row.find(`#${rowId}Col1`).html(lastPubYear);
        row.find(`#${rowId}Col2`).html(count);
        row.find(`#${rowId}Col3`).html(weight);
        row.find(`#${rowId}Col4`).append(whyAnchor);

        hoverLight(row);
    }
}
function detailsParseNarrow(target, jsonData) {
    let narrowDiv = $(`<div class="${gCommon.showXsSmallHideOthers}"></div>`);
    target.append(narrowDiv);

    let numItems = jsonData.length;
    for (let i=0; i<numItems; i++) {
        let stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";

        let cellId = `cell-${i}`;
        let cell = $(`<div id="${cellId}" class="${stripeClass}"></div>`);
        narrowDiv.append(cell);

        let conn = jsonData[i];

        let url = conn.URL;

        let name = conn.DisplayName;
        let nameA = createAnchorElement(name, url);

        let lastPubYear = conn.LastPubYear;
        let count = conn.Count
        let weight = Number(conn.Weight).toFixed(3);

        let whyPath = conn.WhyPath;

        let whyAnchor = createAnchorElement('Why?', whyPath);
        let wideVsNarrow = false;

        twoColumnInfo(cell, spanify("Name", 'boldGreen'), nameA,
            `name-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Most Recent Co-Publication", 'boldGreen'), spanify(lastPubYear),
            `lastYear-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Number of Co-Publications", 'boldGreen'), spanify(count),
            `count-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Co-Author Score", 'boldGreen'), spanify(weight),
            `weight-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Why Link", 'boldGreen'), whyAnchor,
            `why-${cellId}`, wideVsNarrow);

        cell.append($('<hr class="tightHr"/>'));
        hoverLight(cell);
    }
}
