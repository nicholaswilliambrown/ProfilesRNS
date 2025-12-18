gConcepts.maxItemsPerCategory = 10;

function categorizeData(data) {
    let categoryNames = data.map(d => d.SemanticGroupName);
    categoryNames = uniqueArray(categoryNames).sort();

    let categories = {};
    for (let name of categoryNames) {
        categories[name] = [];
    }

    for (let datum of data) {
        let category = datum.SemanticGroupName;
        categories[category].push(datum);
    }

    for (let name of categoryNames) {
        categories[name] =
            reverseSortArrayByWeight(categories[name]);
        let size = categories[name].length;

        //https://stackoverflow.com/questions/26568536/remove-all-items-after-an-index
        if (size > gConcepts.maxItemsPerCategory) {
            categories[name].length = gConcepts.maxItemsPerCategory;
        }
    }

    return categories;
}

function conceptsCategoryParser(data) {
    let resultDiv = $('<div></div>');

    let blurbDiv = $(`<div class="blurbDiv mb-3 mt-3 pb-2">
        Concepts listed here are grouped according to their 'semantic' categories. 
        Within each category, up to ten concepts are shown, 
        in decreasing order of relevance.</div>`);
    resultDiv.append(blurbDiv);

    let rowId = "categories";
    let colSpecs = [
        newColumnSpec(`${gCommon.cols4or12}`, $('<div></div>')),
        newColumnSpec(`${gCommon.cols4or12}`, $('<div></div>')),
        newColumnSpec(`${gCommon.cols4or12}`, $('<div></div>'))
    ];
    let bigRow = makeRowWithColumns(resultDiv, rowId, colSpecs);

    let firstCol = bigRow.find(`#${rowId}Col0`);
    let secondCol = bigRow.find(`#${rowId}Col1`);
    let thirdCol = bigRow.find(`#${rowId}Col2`);

    let categories = categorizeData(data);
    let categoryNames = Object.keys(categories);
    let numCategories = categoryNames.length;

    let target;
    for (let i=0; i<numCategories; i++) {
        let name = categoryNames[i];
        let items = categories[name];

        if (i < numCategories/3) {
            target = firstCol;
        }
        else if (i < 2*numCategories/3) {
            target = secondCol;
        }
        else {
            target = thirdCol;
        }

        emitOneCategory(target, name, items);
    }

    return resultDiv;
}
function emitOneCategory(target, name, items) {
    target.append($(`<div class="categoryHeader">${name}</div>`));

    for (let item of items) {
        let url = `${item.URL}`;
        target.append($(`<div class="categoryItem"><a class="link-ish " href="${url}">${item.Name}</a></div>`));
    }
}


