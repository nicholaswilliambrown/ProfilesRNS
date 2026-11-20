function prepareDropdownData(data) {
    let result = [];
    let sortedOtherOptionsData = prepareTwoLevelOptionsData(data.OtherOptions);
    let sortedHasSectionsData = prepareTwoLevelOptionsData(data.HasSections);

    if (sortedOtherOptionsData && ! sortedOtherOptionsData.length) {
        $('#otherOptionsUlDiv').addClass('d-none');
    }
    if (sortedHasSectionsData && ! sortedHasSectionsData.length) {
        $('#hasSectionsUlDiv').addClass('d-none');
    }
    result.push ({
        label: 'Institution',
        prefix: 'institutions',
        displayProperty: "InstitutionName",
        singular: true,
        list: data.Institutions});
    result.push({
        label: 'Department',
        prefix: 'departments',
        displayProperty: "DepartmentName",
        singular: true,
        list: data.Departments});
    result.push({
        label: 'Faculty Type',
        prefix: 'facultyTypes',
        displayProperty: "FacultyRank",
        list: data.FacultyType,
        useMultiCheckbox: true});
    result.push({
        label: 'Profile Contains',
        prefix: 'hasSections',
        displayProperty: "PersonFilter",
        list: sortedHasSectionsData,
        useMultiCheckbox: true,
        categoryProperty: "PersonFilterCategory"});
    result.push({
        label: 'Other Options',
        prefix: 'otherOptions',
        displayProperty: "PersonFilter",
        list: sortedOtherOptionsData,
        useMultiCheckbox: true,
        categoryProperty: "PersonFilterCategory"});

    return result;
}
function prepareTwoLevelOptionsData(data) {
    let result = [];

    if (data) {
        let categories = sortArrayViaSortLabel(data, 'CategorySort');

        for (let i = 0; i < categories.length; i++) {
            let category = categories[i];
            let categoryName = category.PersonFilterCategory;
            let filters = sortArrayViaSortLabel(category.PersonFilters, "PersonFilterSort");
            for (let i = 0; i < filters.length; i++) {
                let filter = filters[i];
                let item = {
                    "NodeID": filter.NodeID,
                    "PersonFilter": filter.PersonFilter,
                    "PersonFilterCategory": categoryName,
                };
                result.push(item);
            }
        }
    }
    return result;
}

function adjustedSelections(dropdownPrefix, list) {
    gSearch[dropdownPrefix].rawSelections = list;
    gSearch[dropdownPrefix].selectedIndices = list;

    showSearchFilterSelections(dropdownPrefix);
}

// Search filters (a11y R1/R2), built on the markup in searchForm.html:
//   single choice (Institution, Department): a native <select>, plus an "All except" checkbox
//   multiple choice (Faculty Type, Profile Contains, Other Options): a disclosure button
//     (aria-expanded) that shows/hides a <fieldset> of <label>-wrapped checkboxes,
//     with a nested <fieldset><legend> per category where there are categories.
// Selections are still kept as item indices in gSearch[prefix].rawSelections / selectedIndices,
// so collectDropdownSelections() and the search request are unchanged.
function setupDropdowns() {

    let peoplePaneBox = $(`#${gSearch.people}Box`);

    let selectDataLists = prepareDropdownData(gSearch.formData);

    let dropdownsAndNames = $(`#dropdownsAndNames`);
    moveContentTo(dropdownsAndNames, peoplePaneBox);

    gSearch.dropdownPrefixes = [];
    gSearch.prefix2jsonLabel ={};
    gSearch.prefix2singular = {};

    for (let j=0; j<selectDataLists.length; j++) {
        let data = selectDataLists[j];

        let items = data.list;
        if (data.label == 'Department') {
            items = sortArrayViaSortLabel(items, "DepartmentName");
        }

        // no dropdown if no items to list!
        if ( ! items.length) {
            continue;
        }

        let displayProperty = data.displayProperty;

        let dropdownPrefix = data.prefix;
        gSearch[dropdownPrefix] = { items: items, displayProperty: displayProperty };
        gSearch.dropdownPrefixes.push(dropdownPrefix);
        gSearch.prefix2jsonLabel[dropdownPrefix] = data.label.replaceAll(" ", "");
        gSearch.prefix2singular[dropdownPrefix] = data.singular;
        gSearch[dropdownPrefix].rawSelections = []; // clean initial value
        gSearch[dropdownPrefix].selectedIndices = []; // clean initial value

        let ulDiv = $(`#${data.prefix}UlDiv`);

        let rowId = `dropbox${j}`;
        let row = makeRowWithColumns(dropdownsAndNames, rowId, gSearch.midSectionColspecs,  "pb-1 mt-0 mb-2");

        let dropdownColumnLabel = row.find(`#${rowId}Col0`);
        let dropdownColumnOptions = row.find(`#${rowId}Col1`);
        let dropdownColumnCheckbox = row.find(`#${rowId}Col2`);

        dropdownColumnLabel.addClass("pt-1"); // tweak vertical
        dropdownColumnCheckbox.addClass("pt-2 dropdownCheckbox"); // tweak vertical

        moveContentTo(ulDiv, dropdownColumnOptions);

        if (data.singular) {
            setupSingleChoiceFilter(data, dropdownPrefix, items, ulDiv,
                dropdownColumnLabel, dropdownColumnCheckbox);
        }
        else {
            setupMultiChoiceFilter(data, dropdownPrefix, items, ulDiv, dropdownColumnLabel);
        }
    }

    closeFilterGroupsOnOutsideClick();

    // tighten up selectDisplay box
    $('#hasSectionsUlDiv').find('.gradient').addClass('mt-1 pt-0 pb-0');
    $('#peopleBox').find('#dropbox4Row').addClass('mt-3');
}
function setupSingleChoiceFilter(data, dropdownPrefix, items, ulDiv,
                                 dropdownColumnLabel, dropdownColumnCheckbox) {
    let select = ulDiv.find('select');
    let selectId = select.attr('id');

    // the visible label is now a real <label>, so the template's stand-in aria-label can go
    dropdownColumnLabel.html(`<label for="${selectId}">${data.label}</label>`);
    select.removeAttr('aria-label');

    // option values are item indices; the first option ("None selected", value "") is in the template
    for (let i = 0; i < items.length; i++) {
        let option = $('<option></option>').attr('value', i).html(escapeHTML(items[i][data.displayProperty]));
        select.append(option);
    }

    select.on('change', function() {
        let value = select.val();
        adjustedSelections(dropdownPrefix, value === '' ? [] : [Number(value)]);
    });

    // "All except": the label is deliberately not linked to the box (only precise clicks
    // on the box count), so the box gets its own name. It says which filter it belongs to,
    // because Institution and Department each have one.
    let allExceptCheckbox = $(`<input type="checkbox" class="allExceptCheck" id="${dropdownPrefix}AllExceptCheck"/>`);
    allExceptCheckbox.attr('aria-label', `${data.label}: all except the one selected`);
    let label = $(`<label class="ms-2"> All <span class="bold">except</span> the one selected</label>`);

    dropdownColumnCheckbox.append(allExceptCheckbox);
    dropdownColumnCheckbox.append(label);

    gSearch[dropdownPrefix].allExceptCheckbox = allExceptCheckbox;
}
function setupMultiChoiceFilter(data, dropdownPrefix, items, ulDiv, dropdownColumnLabel) {
    let button = ulDiv.find('.filterToggle');
    let group = ulDiv.find('.filterGroup');

    dropdownColumnLabel.html(data.label);
    showSearchFilterSelections(dropdownPrefix);

    let container = group;
    let currentCategory = "";
    let categoryProperty = data.categoryProperty;

    for (let i = 0; i < items.length; i++) {
        let item = items[i];

        if (categoryProperty) {
            let itemCategory = item[categoryProperty];
            if (itemCategory != currentCategory) {
                currentCategory = itemCategory;
                container = $('<fieldset class="filterCategory"></fieldset>');
                container.append($('<legend></legend>').html(escapeHTML(itemCategory)));
                group.append(container);
            }
        }

        // the input carries the prefix class: harvestCheckedOptions(prefix) finds the boxes by it
        let check = $(`<input type="checkbox" class="${dropdownPrefix} me-1"/>`)
            .attr({id: `${dropdownPrefix}-${item.NodeID}`, value: i, 'data-node-id': item.NodeID});
        let label = $('<label class="filterOption d-block"></label>');
        label.append(check).append($('<span></span>').html(escapeHTML(item[data.displayProperty])));
        container.append(label);
    }

    group.on('change', `input.${dropdownPrefix}`, function() {
        let selections = harvestCheckedOptions(dropdownPrefix).map(Number);
        gSearch[dropdownPrefix].rawSelections = selections;
        gSearch[dropdownPrefix].selectedIndices = selections;
        showSearchFilterSelections(dropdownPrefix);
    });

    setupFilterToggle(button, group, ulDiv);
}
// Restore a previous search's filter choices, given NodeIDs (replaces clicking the old <li>s).
function restoreDropdownSelections(nodeIds) {
    let wanted = new Set(nodeIds.map(String));

    for (let dropdownPrefix of gSearch.dropdownPrefixes) {
        let items = gSearch[dropdownPrefix].items;
        let indices = [];
        items.forEach((item, i) => {
            if (wanted.has(String(item.NodeID))) {
                indices.push(i);
            }
        });

        if (gSearch.prefix2singular[dropdownPrefix]) {
            indices = indices.slice(0, 1);
            $(`#${dropdownPrefix}UlDiv select`).val(indices.length ? String(indices[0]) : '');
        }
        else {
            $(`input.${dropdownPrefix}`).each(function() {
                this.checked = indices.includes(Number(this.value));
            });
        }
        adjustedSelections(dropdownPrefix, indices);
    }
}
function showSearchFilterSelections(dropdownPrefix, target) {
    let displayProperty = gSearch[dropdownPrefix].displayProperty;
    let selectedIndices = gSearch[dropdownPrefix].rawSelections;
    let items = gSearch[dropdownPrefix].items;

    if (! target) {
        let itemDiv = $(`#${dropdownPrefix}UlDiv`);
        target = itemDiv.find('.theChosen');
    }

    let list = selectedIndices.map(i => escapeHTML(items[i][displayProperty]));
    let howMuch = list.length;
    let result = gSearch.selectedSt;
    let addEllipsis = false;

    if (howMuch == 0) {
        result = gSearch.noneSt + result;
    }
    else if (howMuch > 2) {
        result = howMuch + result;
    }
    else {
        let joinStr = `<span class="bold"> ${(dropdownPrefix == 'facultyTypes' ? 'or ' : 'and ')}</span>`;
        let truncateAt = 65;
        let fullResult = list.join(joinStr);
        let truncatedResult = fullResult.substring(0, truncateAt);
        if (fullResult != truncatedResult) {
            addEllipsis = true;
        }
        result = truncatedResult;
    }

    target.html(result);
    if (addEllipsis) {
        target.append($('<span class="bold">...</span>'))
    }
}
function indicesToItems(items, indices) {
    let result = indices.map(i => items[i]);
    return result;
}
function collectDropdownSelections(selections) {
    for (let dropdownPrefix of gSearch.dropdownPrefixes) {
        let items = gSearch[dropdownPrefix].items;

        let jsonNodeIDLabel = gSearch.prefix2jsonLabel[dropdownPrefix];
        let jsonNameLabel = jsonNodeIDLabel + 'Name';
        let singular = gSearch.prefix2singular[dropdownPrefix];

        let indices = gSearch[dropdownPrefix].selectedIndices;

        let selectedItems = indicesToItems(items, indices);
        let selectedNodeIDs = selectedItems.map(item => item.NodeID);
        let selectedNames = selectedItems.map(item => item[gSearch[dropdownPrefix].displayProperty]);
        if (singular) {
            selectedNodeIDs = selectedItems.length > 0 ? `${selectedNodeIDs[0]}` : '';
            selectedNames = selectedItems.length > 0 ? `${selectedNames[0]}` : '';
            let allExceptCheckbox = gSearch[dropdownPrefix].allExceptCheckbox;
            selections[`${jsonNodeIDLabel}Except`] = allExceptCheckbox.is(':checked');

            selections[jsonNodeIDLabel] = selectedNodeIDs;
            selections[jsonNameLabel] = selectedNames;
        }
        else {
            // post ProfileContains piggy-backed on OtherOptions
            if (jsonNodeIDLabel == "ProfileContains") {
                jsonNodeIDLabel = "OtherOptions";
                jsonNameLabel = "OtherOptionsName";
            }
            // in case we process ProfileContains before seeing OtherOptions
            if (!selections[jsonNodeIDLabel]) {
                selections[jsonNodeIDLabel] = [];
                selections[jsonNameLabel] = [];
            }
            selections[jsonNodeIDLabel] = selections[jsonNodeIDLabel].concat(selectedNodeIDs);
            selections[jsonNameLabel] = selections[jsonNameLabel].concat(selectedNames);
        }
    }
}