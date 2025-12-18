
async function setupThreeSorts() {
    let [json] = await commonSetupWithJson();
    let data = json[0].ModuleData;

    $('#modules-right-div').remove(); // just one (AKA 'left') side for this page
    let target = $('#modules-left-div');
    target[0].className = 'w-100 pe-0';

    innerCurtainsDown(target);

    let title = getValFromPropertyLabel(json[0].ModuleData, 'label', 'Value');
    target.prepend($(`<h2 class="page-title">${title}</h2>`));
    // $('.topOfPageItems').append($(`<h2 class="page-title">${title}</h2>`));
    setTabTitleAndOrFavicon(`${title}`);

    threeSortsParse(target, data);

    innerCurtainsUp(target);
}

function threeSortify(target, propsArray, labelToIgnore) {
    // input looks a bit like a sparse 3-dimensional array
    let threeProps = [];

    for (let p of propsArray) {
        let propLabel = p.PropertyLabel;
        if (labelToIgnore && labelToIgnore == propLabel) {
            continue;
        }

        let groupSort = parseInt(p.PropertyGroupSort); // make sure it's a number
        let groupLabel = String(p.PropertyGroupLabel); // make sure it's a string
        let propSort = parseInt(p.PropertyGroupInnerSort);
        let valSortOrder = parseInt(p.SortOrder);
        let valUrl = p.URL ? p.URL : "";
        let val = String(p.Value);

        let group = threeProps.find(g => g.groupLabel == groupLabel);
        if (!group) {
            group = {groupLabel: groupLabel, groupSortOrder: groupSort, props: []};
            threeProps.push(group);
        }

        let property = group.props.find(p => p.propLabel == propLabel);
        if (!property) {
            property = {propLabel: propLabel, propSortOrder: propSort, vals: []};
            group.props.push(property);
        }

        let val0 = {valSortOrder: valSortOrder, val: val, valUrl: valUrl};
        property.vals.push(val0);
    }

    console.log("Array: ", threeProps);

    let result = threeProps;
    return result;
}

function threeSortsParse(target, data) {
    let groupsArray = threeSortify(target, data, 'label');

    for (let group of sortArrayViaSortLabel(groupsArray, "groupSortOrder")) {
        let groupLabel = group.groupLabel;
        let innerAccordionInfo1st = makeAccordionDiv(groupLabel, groupLabel, AccordionNestingOption.Unnested)
        let innerPayloadDiv1st = innerAccordionInfo1st.payload;
        target.append(innerAccordionInfo1st.outerDiv);

        for (let prop of sortArrayViaSortLabel(group.props, 'propSortOrder')) {
            let propLabel = prop.propLabel;

            let innerAccordionInfo2nd = makeAccordionDiv(propLabel, propLabel, AccordionNestingOption.Nested)
            let innerPayloadDiv2nd = innerAccordionInfo2nd.payload;
            innerPayloadDiv1st.append(innerAccordionInfo2nd.outerDiv);

            for (let valObject of sortArrayViaSortLabel(prop.vals, 'valSortOrder')) {
                let element;

                if (valObject.valUrl) {
                    element = createAnchorElement(valObject.val, valObject.valUrl);
                }
                else {
                    element = spanify(valObject.val);
                }
                divEltTo(element, innerPayloadDiv2nd);
            }
        }
    }
}
