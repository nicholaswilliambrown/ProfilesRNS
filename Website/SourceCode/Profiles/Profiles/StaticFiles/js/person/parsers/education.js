function educationParser(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let sortedJson = sortArrayViaSortLabel(json, "SortOrder");

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];

        let colSpecs = [
            newColumnSpec(`${gCommon.cols3or12}`),
            newColumnSpec(`${gCommon.cols1}`),
            newColumnSpec(`${gCommon.cols1or12}`, spanify(orBlank(elt.Degree))),
            newColumnSpec(`${gCommon.cols2or12}`, spanify(orBlank(elt.CompletionDate))),
            newColumnSpec(`${gCommon.cols5or12}`, spanify(orBlank(elt.Field)))
        ];
        let row = makeRowWithColumns(innerPayloadDiv, `educ-${i}`, colSpecs, "my-mb2");

        // word wrap pattern
        let institutionInfo = orBlank(elt.Institution);
        if (elt.Location) {
            institutionInfo += ', ' + elt.Location;
        }
        let wrapDiv = $(`<div class="wrap ${gCommon.bsMarginVarying}">${institutionInfo}</div>`);
        row.find(`#educ-${i}Col0`).append(wrapDiv);
    }
}
