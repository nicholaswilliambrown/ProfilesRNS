function detailsParse(target, moduleJson) {

    let jsonData = moduleJson.ModuleData;

    target.append(`<div class="mt-2">${gCoauthor.coauthorsWithDash} are listed by decreasing relevence ` +
        'which is based on the number of co-publications and the years which ' +
        'they were written.</div>')
    target.append('<hr class="mt-2"/>');

    let colspecs = [
        newColumnSpec(`${gCommon.cols5or12} bordE `),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols2or12} bordE t-center`),
        newColumnSpec(`${gCommon.cols2or12} bordE  t-center`),
        newColumnSpec(`${gCommon.cols1or12} pe-0 `)
    ];

    let rowId = `detailsTable`;
    let row = makeRowWithColumns(target, rowId, colspecs, "bordersRow stripe");

    row.find(`#${rowId}Col0`).html('<strong>Name</strong>').addClass("pt-2");
    row.find(`#${rowId}Col1`).html('<strong>Most Recent Co-Publication</strong>');
    row.find(`#${rowId}Col2`).html('<strong>Number of Co-Publications</strong>');
    row.find(`#${rowId}Col3`).html('<strong>Co-Author Score</strong>').addClass("pt-2");
    row.find(`#${rowId}Col4`).html('<strong>Why?</strong>').addClass("pt-2");

    let numItems = jsonData.length;
    for (let i=0; i<numItems; i++) {
        let conn = jsonData[i];
        let stripeClass = (i%2 == 1) ? "stripe" : "";

        let url = `${conn.URL}`;
        let name = conn.DisplayName;
        let nameUrl = createAnchorElement(name, url);

        let lastPubYear = conn.LastPubYear;
        let count = conn.Count
        let weight = Number(conn.Weight).toFixed(3);

        let whyPath = conn.WhyPath;

        let whyAnchor = createAnchorElement('Why?', `${whyPath}`);

        let rowId = `details-${i}`;
        row = makeRowWithColumns(target, rowId, colspecs,
            `ms-1 bordersRow ${stripeClass}`);

        row.find(`#${rowId}Col0`).html(nameUrl);
        row.find(`#${rowId}Col1`).html(lastPubYear);
        row.find(`#${rowId}Col2`).html(count);
        row.find(`#${rowId}Col3`).html(weight);
        row.find(`#${rowId}Col4`).append(whyAnchor);

        hoverLight(row);
    }
}

