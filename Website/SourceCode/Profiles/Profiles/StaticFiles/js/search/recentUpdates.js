function emitSidebarRecentUpdates() {
    // data comes in as strings, needs to be html objects
    // https://stackoverflow.com/questions/54186016/how-do-i-use-the-javascript-map-function-with-object-literals
    let items = gSearch.formData.ProfilesStats.map((item) =>
        ({lhs: spanify(item.count), rhs: spanify(item.label) }));

    let target = gSearch.lhsDiv;
    emitLeftColumnPairs(
        target,
        items,
        'count',
        'label',
        'Profiles',
        'Stats',
        'pStats',
        'statsClass');

    target.append($('<hr class="tightHr"/>'));

    emitLeftColumnPairs(target,
        [],
        '', '',
        'Recent', 'Updates',
        'rUpdates');

    let dataUrl = activityUrlFromSchema(
        gSearch.activityDetailsUrl,
        gSearch.activityPreviewCount,
        gSearch.activityCurrentHighId);

    $.get(dataUrl, function(activities) {
        emitActivityRows(activities, target);

        // proceed w 'continuation'
        emitMoreUpdatesLink();
    });
}
function activityThumbnailAndDate(activity) {
    let date = dateStringToMDY_1(activity.createdDT.replace(/T.*/, ""));

    let personUrl = activity.URL;
    let name = `${activity.firstname} ${activity.lastname}`;
    let nameEntry = createAnchorElement(name, personUrl);

    let thumbnailUrl = gCommon.personThumbnailSchema
        .replace(gCommon.schemaPlaceholder, activity.nodeid);
    let thumbnail = $(`<img src="${thumbnailUrl}"/>`);

    let nameDateDiv = $('<div></div>');
    nameDateDiv.append(nameEntry);
    let dateDiv = divSpanifyTo(date, nameDateDiv, 'recentUpdateDate');
    nameDateDiv.append(dateDiv);
    return {thumbnail, nameDateDiv};
}

function emitActivityRows(activities, target) {
    for (let i=0; i<activities.length; i++) {
        let activity = activities[i];

        let {thumbnail, nameDateDiv} = activityThumbnailAndDate(activity);

        let pairRow = emitLeftColumnPairs(target,
            [{lhs: thumbnail, rhs: nameDateDiv}],
            '',
            '',
            '',
            '',
            `rUpdates${i}`,
            "",
            true);
        emitActivityBlurb(activity, pairRow);
    }
}
function emitLeftColumnPairs(target,
                             items,
                             lhs, rhs,
                             lHeader, rHeader,
                             idPrefix,
                             klass,
                             addHr) {
    if (! klass) {
        klass = "";
    }

    let colspecs = [
        newColumnSpec(`${gCommon.cols4or12} ${klass} pe-2 d-flex justify-content-end`),
        newColumnSpec(`${gCommon.cols8or12} ${klass} ps-0 d-flex justify-content-start `)
    ];

    let rowId = idPrefix;
    let row = makeRowWithColumns(target, rowId, colspecs, "bold");
    row.find(`#${rowId}Col0`).html(lHeader);
    row.find(`#${rowId}Col1`).html(rHeader);

    if (items.length > 0) {
        for (let i=0; i<items.length; i++) {
            let item = items[i];
            rowId = `${idPrefix}${i}`;
            row = makeRowWithColumns(target, rowId, colspecs);

            let col0 = row.find(`#${rowId}Col0`);
            let col1 = row.find(`#${rowId}Col1`);

            col0.append(item.lhs);
            col1.append(item.rhs);

            if (addHr) {
                target.append($('<hr class="tightHr"/>'));
            }
        }
    }

    // last row
    return row;
}
function emitActivityBlurb(activity, target) {
    let tokens = gSearch.recentUpdateTokens;
    tokens.peud = "Profiles.Edit.Utilities.DataIO";

    tokens.AddPublication =         tokens.peud + ".AddPublication";
    tokens.AddCustomPublication =   tokens.peud + ".AddCustomPublication";
    tokens.UpdateSecuritySetting =  tokens.peud + ".UpdateSecuritySetting";
    tokens.AddUpdateFunding =       tokens.peud + ".AddUpdateFunding";
    tokens.Add =                    tokens.peud + ".Add";
    tokens.Update =                 tokens.peud + ".Update";
    tokens.Login =                  "Profiles.Login.Utilities.DataIO.UserLogin";

    tokens.ResearcherRole                   = "http://vivoweb.org/ontology/core#ResearcherRole";
    tokens.PubmedLoadDisambiguationResults  = "[Profile.Data].[Publication.Pubmed.LoadDisambiguationResults]";
    tokens.AddPMID                          = "Add PMID";
    tokens.LoadProfilesData                 = "[Profile.Import].[LoadProfilesData]";
    tokens.PersonInsert                     = "Person Insert";
    tokens.PersonUpdate                     = "Person Update";
    tokens.FundingLoadDisambiguationResults = "[Profile.Data].[Funding.LoadDisambiguationResults]";
    tokens.hasMemberRole                    = "http://vivoweb.org/ontology/core#hasMemberRole";
    
    let agreementLabel  = orNA(activity.AgreementLabel);
    let property        = orNA(activity.property);
    let methodName      = orNA(activity.methodName);
    let param1          = orNA(activity.param1);
    let param2          = orNA(activity.param2);
    let propertyLabel   = orNA(activity.propertyLabel);
    let groupName       = orNA(activity.groupName);

    let journalTitle    = orNA(activity.JournalTitle);
    if (property == tokens.ResearcherRole) {
        journalTitle = agreementLabel;
    }

    let body = gCommon.NA;  // hope to provide a useful value below

    if (methodName == tokens.AddPublication) {
        body = "added a publication from: " + journalTitle;
    }
    else if (methodName == tokens.AddCustomPublication) {
        body = "added \"" + param1 + "\" into " + propertyLabel +
            " section : " + param2;
    }
    else if (methodName == tokens.UpdateSecuritySetting) {
        body = "made \"" + propertyLabel + "\"public";
    }
    else if (methodName == tokens.AddUpdateFunding) {
        body = "added a research activity or funding: " + journalTitle;
    }
    else if (methodName == tokens.FundingLoadDisambiguationResults) {
        body = "has a new research activity or funding: " + journalTitle;
    }
    else if (property == tokens.hasMemberRole) {
        body = "joined group: " + groupName;
    }
    else if (property == tokens.Add) {
        if (param1 != gCommon.NA)
        {
            body = body = "added \"" + param1 + "\" into " + propertyLabel + " section";
        }
        else
        {
            body = "added \"" + propertyLabel + "\" section";
        }
    }
    else if (methodName == tokens.Update) {
        if (param1 != gCommon.NA)
        {
            body = "updated \"" + param1 + "\" in " + propertyLabel + " section";
        }
        else
        {
            body = "updated \"" + propertyLabel + "\" section";
        }
    }
    else if (methodName == tokens.PubmedLoadDisambiguationResults && param1 == tokens.AddPMID) {
        body = "has a new publication listed from: " + journalTitle;
    }
    else if (methodName == tokens.LoadProfilesData && param1 == tokens.PersonInsert) {
        body = "now has a profiles page";
    }
    else if (methodName == tokens.LoadProfilesData && param1 == tokens.PersonUpdate) {
        body = "updated their profiles page";
    }
    else if (methodName == tokens.Login) {
        body = "logged in";
    }
    else {
        body = `<b>Cannot assemble blurb from methodName: 
                    ${methodName}, property: ${property}, and/or param1: ${param1}</b>`;
    }

    divSpanifyTo(body, target, 'recentUpdateBlurb', 'ps-3');
}
