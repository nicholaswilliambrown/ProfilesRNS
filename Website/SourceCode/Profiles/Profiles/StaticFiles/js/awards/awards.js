async function setupAwardsPage() {
    let [json] = await commonSetupWithJson();
    let data = json[0].ModuleData;

    let target = $('#modules-left-div');
    $('#modules-right-div').remove(); // just one (AKA 'left') side for this page

    setupScrolling();

    emitAwardTitle(target, data);
    emitAward(target, data);
}
function emitAwardTitle(target, data) {
    let titleDiv = $(`<div class="page-title mt-2 mb-3">${data.label}</div>`);

    target.append(titleDiv);
}
function emitAward(target, data) {
    let colSpecs = [
        newColumnSpec(`${gCommon.cols2or12} ps-1`),
        newColumnSpec(`${gCommon.cols10or12} ps-2`)
        ];

    let nameDateId = "nameDate";
    let awardeeId = "awardee";
    let nameDateRow = makeRowWithColumns(target, nameDateId, colSpecs, 'mt-2');
    let awardeeRow = makeRowWithColumns(target, awardeeId, colSpecs, 'mt-2');

    let dateRange = "";
    let defaultEndDate = "";
    if (data.startDate) {
        dateRange = `${data.startDate} - ${data.endDate ? data.endDate : defaultEndDate}`;
    }
    nameDateRow.find(`#${nameDateId}Col0`).append(dateRange);
    nameDateRow.find(`#${nameDateId}Col1`).append(data.label);

    let personLink = createAnchorElement(data.DisplayName, data.URL);
    awardeeRow.find(`#${awardeeId}Col0`).append('Awardee');
    awardeeRow.find(`#${awardeeId}Col1`).append(personLink);
}

