function similarsDetailsParser(data) {

    let resultDiv = $('<div></div>');

    let blurbDiv = $(`<div class="blurbDiv mb-3 mt-3 pb-2">
        The people in this list are ordered by decreasing similarity.</div>`);
    resultDiv.append(blurbDiv);

    let colspecs = [
        newColumnSpec(`${gCommon.cols5or12} bordE `),
        newColumnSpec(`${gCommon.cols3or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols3or12} bordE  t-center`),
        newColumnSpec(`${gCommon.cols1or12} pe-0 `)
    ];

    let rowId = `detailsTable`;
    let row = makeRowWithColumns(resultDiv, rowId, colspecs, "borderOneSolid stripe");

    row.find(`#${rowId}Col0`).html('<strong>Name</strong>').addClass("pt-2");
    row.find(`#${rowId}Col1`).html('<strong>Also Co-Authors</strong>');
    row.find(`#${rowId}Col2`).html('<strong>Similarity Score</strong>').addClass("pt-2");
    row.find(`#${rowId}Col3`).html('<strong>Why?</strong>').addClass("pt-2");

    data = reverseSortArrayByWeight(data);
    let numItems = data.length;
    for (let i=0; i<numItems; i++) {
        let conn = data[i];
        let stripeClass = (i%2 == 1) ? "stripe" : "";

        let alsoCo = conn.CoAuthor ? "Yes" : "";

        let url = `${conn.URL}`;
        let nameEntry = createAnchorElement(conn.DisplayName, url);

        let weight = Number(conn.Weight).toFixed(3);

        let whyPath = conn.WhyPath;
        let whyAnchor = createAnchorElement('Why?', `${whyPath}`);

        let rowId = `details-${i}`;
        row = makeRowWithColumns(resultDiv, rowId, colspecs,
            `ms-1 borderOneSolid ${stripeClass}`);

        row.find(`#${rowId}Col0`).html(nameEntry);
        row.find(`#${rowId}Col1`).html(alsoCo);
        row.find(`#${rowId}Col2`).html(weight);
        row.find(`#${rowId}Col3`).append(whyAnchor);

        hoverLight(row);
    }
    return resultDiv;
}

