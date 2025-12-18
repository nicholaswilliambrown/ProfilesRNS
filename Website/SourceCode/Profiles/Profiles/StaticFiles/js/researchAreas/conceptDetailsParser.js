function conceptsDetailsParser(data) {
    let resultDiv = $('<div></div>');
    let resultWide = $(`<div class="${gCommon.hideXsSmallShowOthers}"></div>`);
    let resultNarrow = $(`<div class="${gCommon.showXsSmallHideOthers}"></div>`);
    resultDiv.append(resultWide);
    resultDiv.append(resultNarrow);

    let blurbDiv = $(`<div class="blurbDiv mb-3 mt-3 pb-2">
        Concepts are listed by decreasing relevance which is based on many factors, 
        including how many publications the person wrote about that topic, 
        how long ago those publications were written, 
        and how many publications other people have written on that same topic.</div>`);
    resultDiv.append(blurbDiv);

    data = reverseSortArrayByWeight(data);

    conceptDetailsWide(data, resultWide);
    conceptdDetailsNarrow(data, resultNarrow);

    return resultDiv;
}
function conceptDetailsWide(data, wideDiv) {
    let colspecs = [
        newColumnSpec(`${gCommon.cols3or12} bordE `),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols2or12} bordE  t-center`),
        newColumnSpec(`${gCommon.cols1or12} pe-0 `)
    ];

    let rowId = `detailsTable-wide`;
    let row = makeRowWithColumns(wideDiv, rowId, colspecs, "borderOneSolid stripe");

    row.find(`#${rowId}Col0`).html('<strong>Name</strong>');
    row.find(`#${rowId}Col1`).html('<strong>Number of Publications</strong>');
    row.find(`#${rowId}Col2`).html('<strong>Most Recent Publication</strong>');
    row.find(`#${rowId}Col3`).html('<strong>Publications by All Authors</strong>');
    row.find(`#${rowId}Col4`).html('<strong>Concept Score</strong>');
    row.find(`#${rowId}Col5`).html('<strong>Why?</strong>');

    let numItems = data.length;
    for (let i=0; i<numItems; i++) {
        let conn = data[i];

        let stripeClass = "";
       
        if (i == 0) {
            stripeClass = "";
           
        } else {
            stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";
        }

        let url = `${conn.URL}`;
        let nameEntry = createAnchorElement(conn.Name, url,stripeClass);

        let weight = Number(conn.Weight).toFixed(3);

        let whyPath = conn.WhyURL;
        let whyAnchor = createAnchorElement('Why?', `${whyPath}`);

        let rowId = `details-wide-${i}`;
        row = makeRowWithColumns(wideDiv, rowId, colspecs,
            `ms-1 borderOneSolid ${stripeClass}`);

        row.find(`#${rowId}Col0`).html(nameEntry);
        row.find(`#${rowId}Col1`).html(conn.NumPubsThis);
        row.find(`#${rowId}Col2`).html(conn.LastPubYear);
        row.find(`#${rowId}Col3`).html(conn.NumPubsAll);
        row.find(`#${rowId}Col4`).html(weight);
        row.find(`#${rowId}Col5`).append(whyAnchor);

        hoverLight(row);
    }
}
function conceptdDetailsNarrow(data, narrowDiv) {
    let numItems = data.length;
    for (let i=0; i<numItems; i++) {
        let conn = data[i];
        let stripeClass = "";

        if (i == 0) {
            stripeClass = "";

        } else {
            stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";
        }
        let cellId = `cell-${i}`;
        let cell = $(`<div id="${cellId}" class="${stripeClass}"></div>`);
        narrowDiv.append(cell);

        let url = `${conn.URL}`;
        let nameEntry = createAnchorElement(conn.Name, url);

        let weight = spanify(Number(conn.Weight).toFixed(3));

        let whyPath = conn.WhyURL;
        let whyAnchor = createAnchorElement('Why?', `${whyPath}`);

        let wideVsNarrow = false;

        twoColumnInfo(cell, spanify("Name", 'boldGreen'), nameEntry,
            `name-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Number of Publications", 'boldGreen'), spanify(conn.NumPubsThis),
            `name-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Most Recent Publication", 'boldGreen'), spanify(conn.LastPubYear),
            `name-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Publications by All Authors", 'boldGreen'), spanify(conn.NumPubsAll),
            `name-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Concept Score", 'boldGreen'), weight,
            `name-${cellId}`, wideVsNarrow);
        twoColumnInfo(cell, spanify("Why Link", 'boldGreen'), whyAnchor,
            `name-${cellId}`, wideVsNarrow);

        cell.append($('<hr class="tightHr"/>'));
        hoverLight(cell);
    }
}