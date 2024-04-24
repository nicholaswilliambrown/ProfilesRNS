function authShowPlainText() {
    gPerson.authorshipInnerDiv.empty();
    gPerson.authorshipInnerDiv.append(gPerson.pmcBlurb);

    let showPlainDiv = $('<div id="showPlainDiv" class="pt-3"></div>');
    gPerson.authorshipInnerDiv.append(showPlainDiv);

    let plainContentTextarea = $('<textarea id="showPlainDivContent" rows="24" columns="100"></textarea>');

    let showPlainControls = authPlainControls(plainContentTextarea);

    showPlainDiv.append(showPlainControls);
    showPlainDiv.append(plainContentTextarea);


    authLoadPlainContent(plainContentTextarea);
}
function authPlainControls(contentTextarea) {
    let plainControls = $('<div id="showPlainControls" class="mb-3"></div>');
    let startSpan = $('<span class="plainSpan startSpan">Start with: </span>');
    let includeSpan = $('<span class="plainSpan me-1 includeSpan">Include: </span>');

    gPerson.plain.newestRadio = $(`<input name="plain-radio" class="ms-1 plainControl id="plainNewestRadio" plain-radio" type="radio" value="${gPerson.plain.new}" checked/>`);
    let newRadioLabel = $('<label class="ms-1 me-2" plainNewestRadio="lineNumbers">newest</label>');
    gPerson.plain.oldestRadio = $(`<input name="plain-radio" class="plainControl  id="plainOldestRadio" plain-radio" type="radio" value="${gPerson.plain.old}"/>`);
    let oldRadioLabel = $('<label class="ms-1 me-4" plainOldestRadio="lineNumbers">oldest</label>');

    plainControls.append(startSpan)
        .append(gPerson.plain.newestRadio).append(newRadioLabel)
        .append(gPerson.plain.oldestRadio).append(oldRadioLabel);

    // operations on dynamic elements are limited, DOM doesn't grok them right away
    gPerson.plain.newestRadio.on("click", function(e) { gPerson.plain.oldOrNew = gPerson.plain.new; authLoadPlainContent(contentTextarea);});
    gPerson.plain.oldestRadio.on("click", function(e) { gPerson.plain.oldOrNew = gPerson.plain.old; authLoadPlainContent(contentTextarea);});
    gPerson.plain.oldOrNew = gPerson.plain.new;

    gPerson.plain.lineNumbers = $('<input type="checkbox" id="lineNumbers" class="plainControl plainCheckbox" checked/> ' +
        '<label for="lineNumbers" class="me-1"> line numbers</label>');
    gPerson.plain.doubleSpacing = $('<input type="checkbox" id="doubleSpacing" class="plainControl plainCheckbox" checked/> ' +
        '<label for="doubleSpacing" class="me-1"> double spacing</label>');
    gPerson.plain.allAuthors = $('<input type="checkbox" id="allAuthors" class="plainControl plainCheckbox" checked/> ' +
        '<label for="allAuthors" class="me-1"> all authors</label>');
    gPerson.plain.publicationIds = $('<input type="checkbox" id="publicationIds" class="plainControl plainCheckbox" checked/> ' +
        '<label for="publicationIds" class="me-1"> publication IDs</label>');

    plainControls.append(includeSpan)
        .append(gPerson.plain.lineNumbers)
        .append(gPerson.plain.doubleSpacing)
        .append(gPerson.plain.allAuthors)
        .append(gPerson.plain.publicationIds);

    // operations on dynamic elements are limited, DOM doesn't grok them right away
    gPerson.plain.lineNumbers.on("change",    function(e) { authLoadPlainContent(contentTextarea);});
    gPerson.plain.doubleSpacing.on("change",  function(e) { authLoadPlainContent(contentTextarea);});
    gPerson.plain.allAuthors.on("change",     function(e) { authLoadPlainContent(contentTextarea);});
    gPerson.plain.publicationIds.on("change", function(e) { authLoadPlainContent(contentTextarea);});

    return plainControls;
}

function removeMarkup(blurb) {
    let result = blurb.replace(/<.*?>/g, "");
    return result;
}

function authLoadPlainContent(contentTextarea) {
    contentTextarea.empty(); // start fresh

    let pubs;

    if (gPerson.plain.oldOrNew == gPerson.plain.old) {
        pubs = sortPubsByOldest(gPerson.currentDisplayedPubs);
    }
    else {
        pubs = sortPubsByNewest(gPerson.currentDisplayedPubs);
    }

    let lineNumbers     = gPerson.plain.lineNumbers[0].checked;
    let doubleSpacing   = gPerson.plain.doubleSpacing[0].checked;
    let allAuthors      = gPerson.plain.allAuthors[0].checked;
    let publicationIds  = gPerson.plain.publicationIds[0].checked;

    for (let i=0; i<pubs.length; i++) {
        let line = "";

        let pub = pubs[i];
        let lineSpacing = doubleSpacing ? "\n\n" : "\n";

        if (lineNumbers) {
            line += `${i+1}. `;
        }

        if (allAuthors) {
            let unmarkedBlurb = removeMarkup(pub.prns_informationResourceReference);
            line += `${unmarkedBlurb}`;
        }
        else {
            let fullBlurb = pub.prns_informationResourceReference;
            let titleIndex = fullBlurb.indexOf(pub.rdfs_label);
            let authors = pub.prns_informationResourceReference.substring(0, titleIndex);
            let authorsArray = authors.split(",");
            if (authorsArray.length > gPerson.plain.shortNumOfAuthors) {
                let smallerArray = authorsArray.slice(0, gPerson.plain.shortNumOfAuthors);
                authors = smallerArray.join(", ") + ", et al. ";
            }
            let blurbProper = fullBlurb.substring(titleIndex);
            line += (authors + removeMarkup(blurbProper));
        }

        if (publicationIds) {
            let pubIds = [];
            if (pub.bibo_pmid) {
                line += `PMID: ${pub.bibo_pmid}`;
            }
            if (pub.vivo_pmcid) {
                line += `PMCID: ${pub.vivo_pmcid}`;
            }
            if (pubIds.length > 0) {
                let content = pubIds.join(", ");
                line += ` ${content}`;
            }
        }
        line += lineSpacing;
        contentTextarea.append(line);
    }
}
