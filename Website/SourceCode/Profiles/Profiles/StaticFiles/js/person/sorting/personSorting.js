function comparePersonModules(m1, m2) {
    let m1Name = m1.DisplayModule.replace("Person.", "");
    let m2Name = m2.DisplayModule.replace("Person.", "");

    let m1Info = whichParserInfo(m1Name);
    let m2Info = whichParserInfo(m2Name);

    let m1Rank = m1Info ? m1Info.sort : 300 ; // big number
    let m2Rank = m2Info ? m2Info.sort : 300 ; // big number

    //console.log(`m1: ${m1Name}, ${m1Rank}. m2: ${m2Name}, ${m2Rank}. result: ${m1Rank - m2Rank}`)
    return  m1Rank - m2Rank;
}
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
