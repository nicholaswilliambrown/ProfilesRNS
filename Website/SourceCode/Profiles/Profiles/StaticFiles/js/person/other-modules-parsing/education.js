function educationParser(json, moduleTitle, miscInfo) {
    let accordionBannerTitle = miscInfo.bannerText;

    let innerAccordionInfo = makeAccordionDiv(moduleTitle, accordionBannerTitle, AccordionNestingOption.Nested)
    let innerPayloadDiv = innerAccordionInfo.payload;

    let sortedJson = sortArrayViaSortLabel(json, "SortOrder");

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];

        let colSpecs = [
            newColumnSpec(`${gCommon.cols3or12}`),
            newColumnSpec(`${gCommon.cols1}`),
            newColumnSpec(`${gCommon.cols1or12}`, spanify(elt.Degree)),
            newColumnSpec(`${gCommon.cols2or12}`, spanify(elt.CompletionDate)),
            newColumnSpec(`${gCommon.cols5or12}`, spanify(elt.Field))
        ];
        let row = makeRowWithColumns(innerPayloadDiv, `educ-${i}`, colSpecs, "my-mb2");

        // word wrap pattern
        let wrapDiv = $(`<div class="wrap ${gCommon.bsMarginVarying}">${elt.Institution}, ${elt.Location}</div>`);
        row.find(`#educ-${i}Col0`).append(wrapDiv);
    }

    return innerAccordionInfo.outerDiv;
}
