function similarsListParser(data) {
    let resultDiv = $('<div></div>');

    let blurbDiv = $(`<div class="blurbDiv mb-3 mt-3 pb-2">
        The people in this list are ordered by decreasing similarity. 
        (* These people are also co-authors.)</div>`);
    resultDiv.append(blurbDiv);

    let rowId = "listItems";
    let colSpecs = [
        newColumnSpec(`${gCommon.cols4or12}`, $('<div></div>')),
        newColumnSpec(`${gCommon.cols8or12}`, $('<div></div>')),
    ];
    let bigRow = makeRowWithColumns(resultDiv, rowId, colSpecs, "ps-4");

    let firstHalf = bigRow.find(`#${rowId}Col0`);
    let secondHalf = bigRow.find(`#${rowId}Col1`);
    let size = data.length;

    data = sortArrayViaSortLabel(data, 'Weight', true);

    for (let i=0; i<size; i++) {
        let datum = data[i];

        let asterisk = datum.CoAuthor ? "*" : "";

        let target = i < size/2 ? firstHalf : secondHalf;
        let url = `${datum.URL}`;
        let entry = ($(`<li ><a class="link-ish" href="${url}">
            ${datum.Name}${asterisk}</a></li>`));
        target.append(entry);
    }

    return resultDiv;
}
