function mentorJobOpportunityParser(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let list = $('<ol></ol>');
    innerPayloadDiv.append(list);

    for (let i=0; i<json.length; i++) {
        let elt = json[i];
        let li = $('<li class="mb-2"></li>');
        list.append(li);

        li.append($(`<div class="mb-2 bold">${elt.title}</div>`));
        li.append($(`<div class="mb-2">${elt.jobDescription}</div>`));
        let categories = Object.keys(elt).filter(k => k.match(/^category/) && elt[k] == true);
        let category = categories.length > 0 ? categories[0].replace(/category/,"") : gCommon.NA;
        let colSpecs = [
            newColumnSpec(`${gCommon.cols6or12}`, spanify(`Job Category: ${category}`)),
            newColumnSpec(`${gCommon.cols6or12}`, spanify(`Job URL: `))
        ];
        let id = `mentorOpp-${i}`;
        let row = makeRowWithColumns(li, id, colSpecs, "ps-0");
        let anchor = createAnchorElement(elt.jobURL);
        row.find(`#${id}Col1`).append(anchor);
    }
    return innerPayloadDiv;
}
function mentorOverviewParser(json, moduleTitle, miscInfo, explicitTarget) {
    let innerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let blurbDiv = $(`<div class="mb-2">${json.text}</div>`);
    innerPayloadDiv.append(blurbDiv);

    let areas = Object.keys(json)
        .filter(a => a != 'text')
        .filter(a => json[a] == true);
    if (areas.length) {
        innerPayloadDiv.append($('<div>Available to mentor:</div>'));
        let list = $('<ul></ul>');
        innerPayloadDiv.append(list);
        for (let area of areas) {
            // https://stackoverflow.com/questions/18379254/regex-to-split-camel-case
            area = area.replace(/([a-z])([A-Z])/g, '$1 $2')
                .replace(/ On /, " on ");
            area = initialCap(area);
            list.append($(`<li>${area}</li>`));
        }
    }
    return innerPayloadDiv;
}


