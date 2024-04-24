
async function getPageJSON() {
    try {
        let json = JSON.parse(g.dataURLs);
        let dataPath = json[0].dataURL; // data-existence sanity test

        if (dataPath) {
            let jsonTmp = [];
            for (let k=0; k<json.length; k++) {
                let jsonK = json[k]
                let jsonURL = g.apiBasePath + "?" + jsonK.dataURL;
                await jQuery.getJSON(jsonURL, function (json2) {
                    for (let j2=0; j2<json2.length; j2++) {
                        let jsonJ2 = json2[j2];
                        jsonTmp.push(jsonJ2)
                    }
                    g.pageJSON = jsonTmp;
                });
            }
        }
    }
    catch (error) {
        console.log("Oops: ", error);
        g.pageJSON = [];
    }
    return; // handy for breakpoint
}
