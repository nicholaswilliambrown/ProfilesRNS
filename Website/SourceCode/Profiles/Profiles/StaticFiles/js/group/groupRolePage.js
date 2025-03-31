const GroupTab = Object.freeze({
    Name: Symbol("By Name"),
    Role: Symbol("By Role"),
    Map: Symbol("Map"),
    Coauthors: Symbol("Co-Authors")
});

async function setupGroupByName() {
    await groupRoleCommonSetup();
}
async function setupGroupByRole() {
    await groupRoleCommonSetup();
}
async function setupGroupMap() {
    await groupRoleCommonSetup();
}
async function setupGroupCoauthors() {
    await groupRoleCommonSetup(true);
}

async function groupRoleCommonSetup(customVsRegularInnerCurtain) {
    await commonSetup();

    let innerCurtains = customVsRegularInnerCurtain ?
        $('.hideTilReady') :
        getMainModuleRow();

    innerCurtainsDown(innerCurtains);

    let modules = await myGetPageJson();

    let labelJson = findModuleDataByName(modules, 'Group.Label');

    let title = labelJson.label;
    let numMembers = labelJson.groupSize;
    let backUrl = labelJson.URL;

    emitTopOfGroupRole(title, numMembers, backUrl);

    adjustTabs();

    mainParse(modules);

    innerCurtainsUp(innerCurtains);
}

function adjustTabs() {
    let myUrl = window.location.href;
    let urlPrefix = myUrl.replace(/.*(\/display\/\d+\/\d+).*/, "$1/");


    let coauthors = "coauthors";
    let byName = "byname";
    let map = "map";

    let toMap = $(`#navTo${GroupTab.Map.description}`);
    let toCoauthors = $(`#navTo${GroupTab.Coauthors.description}`);
    let toRole = $(`#navTo${GroupTab.Role.description.replace(/\s+/,"")}`);
    let toName = $(`#navTo${GroupTab.Name.description.replace(/\s+/,"")}`);

    toRole.attr("href", urlPrefix);
    toName.attr("href", urlPrefix + `${byName}`);
    toCoauthors.attr("href", urlPrefix + `${coauthors}`);
    toMap.attr("href", urlPrefix + `${map}`);

    if (myUrl.match(/coauthors/i)) {
        gGroup.whichTabDiv = toCoauthors;
        gGroup.whichTabSym = GroupTab.Coauthors;
    }
    else if (myUrl.match(/map/i)) {
        gGroup.whichTabDiv = toMap;
        gGroup.whichTabSym = GroupTab.Map;
    }
    else if (myUrl.match(/byname/i)) {
        gGroup.whichTabDiv = toName;
        gGroup.whichTabSym = GroupTab.Name;
    }
    else {
        gGroup.whichTabDiv = toRole;
        gGroup.whichTabSym = GroupTab.Role;
    }

    gGroup.whichTabDiv.addClass("active");
    gGroup.whichTabDiv.removeAttr("href");
}

function emitTopOfGroupRole(title, numMembers, backUrl) {

    let topLhsDiv = createOrGetTopLhsDiv();

    emitCommonTopOfLhs(topLhsDiv, 'Group Members', numMembers,
        backUrl, 'Group Profile', title);

    appendEltFromBigString(gGroup.GroupTabs, topLhsDiv);

    $('#topLhsRow').addClass('mb-3'); // tweak css in common element

    gGroup.GroupTabs = createFlavorTabs(
        [GroupTab.Name.description, GroupTab.Role.description, GroupTab.Map.description, GroupTab.Coauthors.description]);
    let preTop = createOrGetPreTop(topLhsDiv)
    preTop.append(gGroup.GroupTabs);

    return topLhsDiv;
}

function mainParse(modules) {
    let target = $('<div id="topLhs2" class="ps-3 pt-2"></div>');
    $('#topLhsDiv').append(target);

    let module;
    switch (gGroup.whichTabSym) {
        case GroupTab.Name:
            module = findModuleDataByName(modules, 'Group.ContributingRole');
            grByNameParser(module.Members, target);
            break;
        case GroupTab.Role:
            module = findModuleDataByName(modules, 'Group.ContributingRole');
            grByRoleParser(module.Members, target);
            break;
        case GroupTab.Map:
            module = findModuleDataByName(modules, 'Group.Map');
            mapParse(module);
            break;
        case GroupTab.Coauthors:
            moveContentByIdTo('moveableContentDiv', target);
            module = findModuleDataByName(modules, 'Group.Cluster');
            clusterParse(module, true); // true 'for groups'
            break;
    }
}

function grByRoleParser(members, target) {
    members = sortArrayViaSortLabel(members, "LastName");

    target.append($('<div>Member</div>'));

    let listDiv = $('<div class="ps-4"></div>');
    target.append(listDiv);

    let colSpecs = [
        newColumnSpec(`${gCommon.cols4or12}`),
        newColumnSpec(`${gCommon.cols4or12}`),
        newColumnSpec(`${gCommon.cols4or12}`)
    ];

    let numMembers = members.length;
    let rowId = "row";
    let row = makeRowWithColumns(listDiv, rowId, colSpecs, "ps-1");

    for (let i=0; i<numMembers; i++) {
        let member = members[i];
        let name = `${member.LastName}, ${member.FirstName}`;
        let a = createAnchorElement(name, member.URL);

        let whichCol;
        if (i < numMembers / 3 || numMembers <= gGroup.maxBeforeColumnSplit) {
            whichCol = row.find(`#${rowId}Col0`);
        }
        else if (i < 2 * numMembers / 3) {
            whichCol = row.find(`#${rowId}Col1`);
        }
        else {
            whichCol = row.find(`#${rowId}Col2`);
        }
        divEltTo(a, whichCol);
    }
}
function grByNameParser(members, target) {
    members = sortArrayViaSortLabel(members, "LastName");

    let listDiv = $('<div class="ps-4"></div>');
    target.append(listDiv);

    let colSpecs = [
        newColumnSpec(`${gCommon.cols6or12}`),
        newColumnSpec(`${gCommon.cols6or12}`)
    ];

    let numMembers = members.length;
    let rowId = "row";
    let row = makeRowWithColumns(listDiv, rowId, colSpecs, "ps-1");

    for (let i=0; i<numMembers; i++) {
        let member = members[i];
        let name = `${member.LastName}, ${member.FirstName}`;
        let a = createAnchorElement(name, member.URL);

        let whichCol;
        if (i < numMembers / 2 || numMembers <= gGroup.maxBeforeColumnSplit) {
            whichCol = row.find(`#${rowId}Col0`);
        }
        else {
            whichCol = row.find(`#${rowId}Col1`);
        }

        divEltTo(a, whichCol);

        divSpanifyTo(`Member`, whichCol);
        divSpanifyTo(`${member.Title}`, whichCol);
        divSpanifyTo(`${member.InstitutionName}`, whichCol);
        divSpanifyTo(`${member.DepartmentName}`, whichCol);
        divSpanifyTo(` `, whichCol, "mt-3", "mt-3");
    }
}
