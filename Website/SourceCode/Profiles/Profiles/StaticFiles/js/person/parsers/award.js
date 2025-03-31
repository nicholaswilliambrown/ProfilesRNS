function awardParser(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let sortedJson = sortArrayViaSortLabel(json, "SortOrder");

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];

        let colSpecs = [
            newColumnSpec(`${gCommon.cols11or12}`),
        ];
        let row = makeRowWithColumns(innerPayloadDiv, `award-${i}`, colSpecs, "my-mb2");

        // word wrap pattern
        let wrapDiv = $(`<div class="wrap ${gCommon.bsMarginVarying}">${elt.StartYear} ${elt.Name}</div>`);
        row.find(`#award-${i}Col0`).append(wrapDiv);
    }
}
