function compareStringsForSort(s1, s2, reverse) {
    let result;

    if (s1 === s2) result = 0;
    else if (s1 < s2) result = reverse ? -1 : 1;
    else result = reverse ? 1 : -1;

    return result;
}
//https://stackoverflow.com/questions/58360048/get-unique-values-of-a-javascript-array
function uniqueArray(array) {
    let result = Array.from(new Set(array));
    return result;
}
function sortArrayViaSortLabel(array, sortLabel, reverse) {
    let sortedArray = copyArray(orEmptyList(array)).sort((a, b) => {
        let aVal = a[sortLabel];
        let bVal = b[sortLabel];

        let result;
        if (typeof aVal !== 'string') {
            result = reverse ? bVal - aVal : aVal - bVal;
        } else {
            result = reverse ? compareStringsForSort(aVal, bVal) : compareStringsForSort(bVal, aVal)
        }
        return result;
    });
    return sortedArray;
}
function reverseSortArrayByWeight(array) {
    return sortArrayViaSortLabel(array, "Weight", true);
}
function sortModules(personJson, compareFn) {
    let result = personJson;

    // sort iff compareFn exists
    if (compareFn) {
        result = copyArray(personJson).sort(compareFn);
    }
    console.log("F2 rearrange", result);
    return result;
}
// for firefox compatibility -- it doesn't support toSorted()
function copyArray(origArray) {
    let result = origArray.map(x => x);
    return result;
}
function compareExploreModules(m1, m2) {
    let m1Sort = exploreModuleInfo(m1.DisplayModule).sort;
    let m2Sort = exploreModuleInfo(m2.DisplayModule).sort;

    return m1Sort - m2Sort;
}
function exploreModuleInfo(moduleTitle) {
    let sort = 5000; // big number
    let blurb = "need blurb";

    let title = moduleTitle.replace("Person.", "");
    switch (title) {
        case "Concept":
            sort = 10;
            blurb = "Derived automatically from this person's publications.";
            break;
        case "CoAuthors":
            sort = 20;
            blurb = "People in Profiles who have published with this person.";
            break;
        case "Similar":
            sort = 30;
            blurb = "People who share similar concepts with this person.";
            break;
        case "SameDepartment.Top5":
            sort = 40;
            blurb = "People in same department with this person.";
            break;
        case "PhysicalNeighbour.Top5":
            sort = 50;
            blurb = "People whose addresses are nearby this person.";
            break;
        default:
            sort = 1000;
            blurb = "Unknown module: " + title;
    }

    return {
        sort: sort,
        blurb: blurb
    };
}

