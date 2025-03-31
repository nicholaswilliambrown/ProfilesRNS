function similarsDetailsParser(data) {
    let resultDiv = $('<div></div>');
    let resultWide = $(`<div class="${gCommon.hideXsSmallShowOthers}"></div>`);
    let resultNarrow = $(`<div class="${gCommon.showXsSmallHideOthers}"></div>`);
    resultDiv.append(resultWide);
    resultDiv.append(resultNarrow);

    let blurbDiv = $(`<div class="blurbDiv mb-3 mt-3 pb-2">
        The people in this list are ordered by decreasing similarity.</div>`);
    resultDiv.append(blurbDiv);

    data = reverseSortArrayByWeight(data);

    similarsDetailsWide(data, resultWide);
    similarsDetailsNarrow(data, resultNarrow);

    return resultDiv;
}
function similarsDetailsWide(data, wideDiv) {
    let colspecs = [
        newColumnSpec(`${gCommon.cols5or12} bordE `),
        newColumnSpec(`${gCommon.cols3or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols3or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols1or12} pe-0 `)
    ];

    let rowId = `detailsTable`;
    let row = makeRowWithColumns(wideDiv, rowId, colspecs, "borderOneSolid stripe");

    row.find(`#${rowId}Col0`).html('<strong>Name</strong>').addClass("pt-2");
    row.find(`#${rowId}Col1`).html('<strong>Also Co-Authors</strong>').addClass("pt-2");
    row.find(`#${rowId}Col2`).html('<strong>Similarity Score</strong>').addClass("pt-2");
    row.find(`#${rowId}Col3`).html('<strong>Why?</strong>').addClass("pt-2");

    let numItems = data.length;
    for (let i=0; i<numItems; i++) {
        let conn = data[i];
        let stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";

        let alsoCo = conn.CoAuthor ? "Yes" : "";

        let url = `${conn.URL}`;
        let nameEntry = createAnchorElement(conn.DisplayName, url);

        let weight = Number(conn.Weight).toFixed(3);

        let whyPath = conn.WhyPath;
        let whyAnchor = createAnchorElement('Why?', `${whyPath}`);

        let rowId = `details-${i}`;
        row = makeRowWithColumns(wideDiv, rowId, colspecs,
            `ms-1 borderOneSolid ${stripeClass}`);

        row.find(`#${rowId}Col0`).html(nameEntry);
        row.find(`#${rowId}Col1`).html(alsoCo);
        row.find(`#${rowId}Col2`).html(weight);
        row.find(`#${rowId}Col3`).append(whyAnchor);

        hoverLight(row);
    }
}
function similarsDetailsNarrow(data, narrowDiv) {

    let numItems = data.length;
    for (let i=0; i<numItems; i++) {
        let conn = data[i];
        let stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";

        let cellId = `cell-${i}`;
        let cell = $(`<div id="${cellId}" class="${stripeClass}"></div>`);
        narrowDiv.append(cell);

        let alsoCo = conn.CoAuthor ? "Yes" : "";

        let url = `${conn.URL}`;
        let nameEntry = createAnchorElement(conn.DisplayName, url);

        let weight = Number(conn.Weight).toFixed(3);

        let whyPath = conn.WhyPath;
        let whyAnchor = createAnchorElement('Why?', `${whyPath}`);

        let wideVsNarrow = false;

        twoColumnInfo(cell, spanify("Name", 'boldGreen'), nameEntry,
            `name-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Also Co-Authors", 'boldGreen'), spanify(alsoCo),
            `name-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Similarity Score", 'boldGreen'), spanify(weight),
            `name-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Why Link", 'boldGreen'), whyAnchor,
            `name-${cellId}`, wideVsNarrow);

        cell.append($('<hr class="tightHr"/>'));
        hoverLight(cell);
    }
}

