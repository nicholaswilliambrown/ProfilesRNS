function opportunityParser(json, moduleTitle, miscInfo, explicitTarget) {
    let opportunityInnerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let sortedJson = sortArrayViaSortLabel(json, "StartDate", true );

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];
        let p = $('<p></p>');

        let startDate = yyyyDashMmDashDdStarTo(elt.StartDate, fromMatchToDdMdYyyy);
        let endDate = yyyyDashMmDashDdStarTo(elt.EndDate, fromMatchToDdMdYyyy);
        let url = `/profiles/studentopportunities/Detail?id=${elt.StudentOpportunityId}`;

        opportunityInnerPayloadDiv.append(p);
        let loginSpan = gCommon.loggedIn ? "" : '<span className="f10">[login at prompt]</span>'
        let html = `
            <a class="link-ish" href="${url}">${elt.Title}</a> 
            ${loginSpan}
            <div class="mb-1 mt-1">Available: ${startDate}, Expires: ${endDate}</div>
            <div>${elt.Description}</div>
        `;
        p.html(html);
    }
}
function completedProjectParser(json, moduleTitle, miscInfo, explicitTarget) {
    let target = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let sortedJson = sortArrayViaSortLabel(json, "StartDate", true );

    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];

        target.append(`<div>${elt.projecttitle}</div>`);

        let startDate = yyyyDashMmDashDdStarTo(elt.ResearchStart, fromMatchToDdMdYyyy);
        let endDate = yyyyDashMmDashDdStarTo(elt.ResearchEnd, fromMatchToDdMdYyyy);

        let line2 = `${elt.ProgramType}, ${startDate} - ${endDate}`

        target.append(`<div>${line2}</div>`);
    }
}

