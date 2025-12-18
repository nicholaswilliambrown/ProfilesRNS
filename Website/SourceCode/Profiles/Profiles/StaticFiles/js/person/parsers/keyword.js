

function keywordParser(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let sortedJson = sortArrayViaSortLabel(json, "SortOrder");

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];

        let div = $(`<div class="ps-4 link-ish">${elt.Value}</div>`);
        div.on('click', function() {minimalPeopleSearchByTerm(elt.Value)});

        innerPayloadDiv.append(div);
    }
}
