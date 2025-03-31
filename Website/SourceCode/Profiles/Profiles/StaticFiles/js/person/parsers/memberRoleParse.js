

function memberRoleParser(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let sortedJson = sortArrayViaSortLabel(json, "Name");

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];

        let a = createAnchorElement(elt.Name, elt.URL);
        let div = $(`<div class="ps-4"> (Member)</div>`);
        div.prepend(a);

        innerPayloadDiv.append(div);
    }
}
