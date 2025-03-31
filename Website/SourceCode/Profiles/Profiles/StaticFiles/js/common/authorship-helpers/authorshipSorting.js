function sortPubsByNewest(pubs) {
    let sortedPubs = copyArray(pubs).sort((a, b) => {
        return compareStringsForSort(a.prns_publicationDate, b.prns_publicationDate);
    });
    return sortedPubs;
}
function sortPubsByOldest(pubs) {
    let sortedPubs = copyArray(pubs).sort((a, b) => {
        return compareStringsForSort(b.prns_publicationDate, a.prns_publicationDate);
    });
    return sortedPubs;
}
function sortByCitationThenNewest(pubs) {
    let sortedPubs = copyArray(pubs).sort((a, b) => {
        let result = b.PMCCitations - a.PMCCitations;

        if (result == 0) {
            result = compareStringsForSort(a.prns_publicationDate, b.prns_publicationDate);
        }
        return result;
    });
    return sortedPubs;
}
function sortByAltmetricThenReverseChron(pubs) {
    let pubsCopy = copyArray(pubs);

    $('.altmetric-embed a').remove();
    $('.altmetric-embed.altmetric-popover').remove();

    // just until 'real' computation
    pubsCopy.sort((a, b) => {
        let pa = a.bibo_pmid;
        let pb = b.bibo_pmid;

        let aScore = gPerson.altmetricScores[pa] ? gPerson.altmetricScores[pa] : -1;
        let bScore = gPerson.altmetricScores[pb] ? gPerson.altmetricScores[pb] : -1;

        let result = (bScore - aScore);
        if (result == 0) {
            result = compareStringsForSort(b.prns_publicationDate, a.prns_publicationDate);
        }
        return result;
    });
    return pubsCopy;
}
