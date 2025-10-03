
function consoleAltmetricStats(label) {
    let numPmids = $(gPerson.altPmidSelector).length;
    // console.log(`=====> Invoked: ${label}.
    //     numPmids: ${numPmids}.
    //     numCollectedAltMetScores: ${Object.keys(gPerson.altmetricScores).length}.
    //     altMets followed by <a>: ${$('.altmetric-embed>a').length}
    //     `,
    //     gPerson.altmetricScores);
}

function computeAltmetricScores() {
    let didRecompute = false;

    let numAltPmids = $(gPerson.altPmidSelector).length;
    let numAltScores = gPerson.altmetricScores ?
            Object.keys(gPerson.altmetricScores).length
            :0;

    if (numAltPmids != numAltScores) {
        let progressSpan = spanify(`Found ${numAltScores} 
                    out of ${numAltPmids} altMetric scores`, 'altMetricProgress');
        $('#authNavButtonMostDiscussed').append(progressSpan);
        $(gPerson.altPmidSelector).each(function() {
            let pmid = $(this).attr('data-pmid');
            if (gPerson.altmetricScores[pmid] === undefined) {
                let a = $(this).find('a');
                let image = a.find('img');
                if (image.length > 0) {
                    let score = image.attr("alt").replace(/.*score of /, "");
                    gPerson.altmetricScores[pmid] = score;
                }
            }
        });
        numAltScores = Object.keys(gPerson.altmetricScores).length;
        if (numAltScores == numAltPmids) {
            progressSpan.remove();
            gPerson.gotAltmetrics = true;
        }
        didRecompute = true;
    }

    return didRecompute;
}

function showTransOrFieldChecked(elementClass) {
    $(`.${elementClass}`).attr("checked", "checked");
}
function showTransOrFieldUnchecked(elementClass) {
    $(`.${elementClass}`).removeAttr("checked");
}
function transOrFieldClick(elementClass, fieldFilters) {
    if (fieldFilters.includes(elementClass)) {
        console.log(`${elementClass} started out present`);
        showTransOrFieldUnchecked(elementClass);

        // see https://sentry.io/answers/remove-specific-item-from-array/
        fieldFilters.filter((val, index, arr) => {
            if (val == elementClass) {
                arr.splice(index, 1);
                return true;
            }
            return false;
        });
    }
    else {
        console.log(`${elementClass} started out NOT present`);
        showTransOrFieldChecked(elementClass);

        fieldFilters.push(elementClass);
    }
    applySortsFiltersLimits();
}
function addFields(linkItems, pub) {
    let pubFields = pub.Fields;

    if (pubFields && pubFields.length > 0) {
        let knownFieldClasses = Object.keys(gPerson.etlFieldFilterClasses);

        for (let i=0; i<pubFields.length; i++) {
            let pubField = pubFields[i];
            
            let fieldFullName = pubField.BroadJournalHeading;
            let fieldKey = getCleanFieldHeader(fieldFullName);

            let fieldAbbr;
            let fieldStyleClass;

            // this helps if >1 field uses default class -- they filter separately
            let fieldFilterClass = fieldKey;

            if ( ! knownFieldClasses.includes(fieldKey)) {
                fieldStyleClass = gPerson.defaultFieldClass;
                fieldAbbr = pubField.Abbreviation ?
                    pubField.Abbreviation :
                    fieldKey.substring(0,3);
            }
            else {
                fieldAbbr = gPerson.etlFieldAbbrevs[fieldKey];
                fieldStyleClass = gPerson.etlFieldStyleClasses[fieldKey];
            }

            let fieldButton = $(`<button data-bs-toggle="tooltip" 
                            data-bs-placement="top" 
                            data-bs-custom-class="${fieldStyleClass}" 
                            title="${fieldFullName}" 
                            class="me-2 fieldOrTrans ${fieldFilterClass} ${fieldStyleClass}">${fieldAbbr}</button>`);
            fieldButton.on('click', function() {
                transOrFieldClick(fieldFilterClass, gPerson.fieldFilters);
            });

            // prepend label
            if (i == 0) {
                pushStringSpan(linkItems, " Fields: ","pubBadgeField");
            }
            linkItems.push(fieldButton);
        }
    }
}
function addTranslations(linkItems, pub) {
    let translationsAdded = 0;

    for (let i=0; i<gPerson.translations.length; i++) {
            let trans = gPerson.translations[i];

        if ( ! pub[trans.className]) continue;

        translationsAdded++ ;
        let transButton;

        // remove abbreviation formatting
        let transClass = trans.className;
        let transAbbrev = trans.abbr;
        if (trans.ttip) {
            let ttClass = `${transClass}Tt`;
            transButton = $(`<button data-bs-toggle="tooltip" 
                            data-bs-placement="top" 
                            data-bs-custom-class="${ttClass}" 
                            title="${trans.ttip}" 
                            class="fieldOrTrans ${transClass}">${transAbbrev}</button>`); // include the <i> etc
        }
        else {
            transButton = $(`<button class="fieldOrTrans me-2 hover_bold ${transClass}">${transAbbrev}</button>`);
        }
        transButton.on('click', function() {
            transOrFieldClick(transClass, gPerson.translationFilters);
        });

        // prepend label
        if (translationsAdded == 1) { // ie, first one added
            pushStringSpan(linkItems, " Translation: ","pubBadgeField");
        }

        linkItems.push(transButton);
    }
}

function passesTransOrFieldFilters(pub) {
    let passes = false; // burden of proof

    if (gPerson.fieldFilters.length == 0) {
        passes = true;
    }
    else {
        for (let i=0; i<gPerson.fieldFilters.length; i++) {
            let fieldFilterClass = gPerson.fieldFilters[i];
            let pubFields = pub.Fields;
            for (let k=0; k<pubFields.length; k++) {
                let pubField = pubFields[k];
                let pubFieldName = getCleanFieldHeader(pubField.BroadJournalHeading);
                // unknown ('default') fields don't filter
                if (   fieldFilterClass == gPerson.defaultFieldClass
                    || fieldFilterClass == pubFieldName) {

                    passes = true;
                    break;
                }
            }
        }
    }
    for (let j=0; passes && j<gPerson.translationFilters.length; j++) {
        let trans = gPerson.translationFilters[j];

        if ( ! pub[trans]) {
            passes = false;
            break;
        }
    }
    return passes;
}
