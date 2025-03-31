
function conceptsCloudParser(data) {
    let resultDiv = $('<div></div>');

    let blurbDiv = $(`<div class="blurbDiv mb-3 mt-3 pb-2">
        In this concept 'cloud', the sizes of the concepts are based not only on the number of corresponding publications, 
        but also how relevant the concepts are to the overall topics of the publications, 
        how long ago the publications were written, whether the person was the first or senior author, 
        and how many other people have written about the same topic. 
        The largest concepts are those that are most unique to this person.</div>`);
    resultDiv.append(blurbDiv);

    let rowId = "cloudItems";
    let colSpecs = [
        newColumnSpec(`${gCommon.cols4or12}`, $('<div></div>')),
        newColumnSpec(`${gCommon.cols8or12}`, $('<div></div>')),
    ];
    let bigRow = makeRowWithColumns(resultDiv, rowId, colSpecs);

    let firstHalf = bigRow.find(`#${rowId}Col0`);
    let secondHalf = bigRow.find(`#${rowId}Col1`);
    let size = data.length;

    data = sortArrayViaSortLabel(data, 'Name');

    for (let i=0; i<size; i++) {
        let datum = data[i];

        let cloudClass = "cloudRegular";
        if (datum.CloudSize == 1) {
            cloudClass = "cloudLight";
        }
        else if (datum.CloudSize == 5) {
            cloudClass = "cloudBold";
        }

        let target = i < size/2 ? firstHalf : secondHalf;
        let url = `${datum.URL}`;
        let entry = ($(`<div class="${cloudClass}"><a class="link-ish" href="${url}">${datum.Name}</a></div>`));
        target.append(entry);
    }

    return resultDiv;
}
