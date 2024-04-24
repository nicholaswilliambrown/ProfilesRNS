function conceptDetailsParser(data) {

    let resultDiv = $('<div></div>');

    let blurbDiv = $(`<div class="blurbDiv mb-3 mt-3 pb-2">
        Concepts are listed by decreasing relevance which is based on many factors, 
        including how many publications the person wrote about that topic, 
        how long ago those publications were written, 
        and how many publications other people have written on that same topic.</div>`);
    resultDiv.append(blurbDiv);

    let colspecs = [
        newColumnSpec(`${gCommon.cols3or12} bordE `),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols2or12} bordE  t-center`),
        newColumnSpec(`${gCommon.cols1or12} pe-0 `)
    ];

    let rowId = `detailsTable`;
    let row = makeRowWithColumns(resultDiv, rowId, colspecs, "bordersRow stripe");

    row.find(`#${rowId}Col0`).html('<strong>Name</strong>').addClass("pt-2");
    row.find(`#${rowId}Col1`).html('<strong>Number of Publications</strong>');
    row.find(`#${rowId}Col2`).html('<strong>Most Recent Publication</strong>');
    row.find(`#${rowId}Col3`).html('<strong>Publications by All Authors</strong>');
    row.find(`#${rowId}Col4`).html('<strong>Concept Score</strong>').addClass("pt-2");
    row.find(`#${rowId}Col5`).html('<strong>Why?</strong>').addClass("pt-2");

    data = sortArrayViaSortLabel(data, 'Weight', true);
    let numItems = data.length;
    for (let i=0; i<numItems; i++) {
        let conn = data[i];
        let stripeClass = (i%2 == 1) ? "stripe" : "";

        let url = `${conn.URL}`;
        let nameEntry = createAnchorElement(conn.Name, url);

        let weight = Number(conn.Weight).toFixed(3);

        let whyPath = conn.WhyURL;
        let whyAnchor = createAnchorElement('Why?', `${whyPath}`);

        let rowId = `details-${i}`;
        row = makeRowWithColumns(resultDiv, rowId, colspecs,
            `ms-1 bordersRow ${stripeClass}`);

        row.find(`#${rowId}Col0`).html(nameEntry);
        row.find(`#${rowId}Col1`).html(conn.NumPubsThis);
        row.find(`#${rowId}Col2`).html(conn.LastPubYear);
        row.find(`#${rowId}Col3`).html(conn.NumPubsAll);
        row.find(`#${rowId}Col4`).html(weight);
        row.find(`#${rowId}Col5`).append(whyAnchor);

        hoverLight(row);
    }
    return resultDiv;
}

