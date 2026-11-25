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
    let titleH2 = $(`<h2 class="page-title fw-normal mt-2 mb-3">${escapeHTML(data.label)}</h2>`);

    target.append(titleH2);
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
    nameDateRow.find(`#${nameDateId}Col0`).append(escapeHTML(dateRange));
    nameDateRow.find(`#${nameDateId}Col1`).append(escapeHTML(data.label));

    let personLink = createAnchorElement(data.DisplayName, data.URL);
    awardeeRow.find(`#${awardeeId}Col0`).append('Awardee');
    awardeeRow.find(`#${awardeeId}Col1`).append(personLink);
}

