
function overviewParser(json, moduleTitle, miscInfo, explicitTarget) {
    let overviewInnerPayloadDiv = getTargetUntentavizeIfSo(moduleTitle, explicitTarget);

    let sortedJson = sortArrayViaSortLabel(json, "sortOrder");
    let overviewRaw = sortedJson[0].value;


    for (let i=0; i<sortedJson.length; i++) {
        let elt = sortedJson[i];

        elt.value = FindAllURLs(elt.value);

        //Flip to HTML for display
        elt.value = elt.value.replaceAll("[b]", "<b>");
        elt.value = elt.value.replaceAll("[/b]", "</b>");
        elt.value = elt.value.replace("\n", "<br/>");



        let lines = elt.value.split("\n");


        for (let j = 0; j < lines.length; j++) {

            let line = lines[j];


            let item = $(`<div class="mb-2">${line}</div>`);
            overviewInnerPayloadDiv.append(item);
        }
    }
}

  function FindAllURLs(overview)
{
            var _overview = "";

      var urlsWithText = [];
    var urlsOnly = [];
    urlsWithText = overview.split("[url=");

    urlsWithText.forEach(function(url)
    {
        if (!~url.indexOf("[/url]")) {
            _overview += url;
        }
        else {

           var urls2 = [];
            urls2 = url.split("[/url]");

            _overview += "<a target='_blank' rel='noopener noreferrer' href='" + urls2[0].split(']')[0] + "'>" + urls2[0].split(']')[1] + "</a>";

            for (let i = 1; i < urls2.length; i++)
            {
                _overview += urls2[i] + (~urls2[i].indexOf("[url]") ? "[/url]" : "");
            }

        }
    });

    urlsOnly = _overview.split("[url]");
    _overview = "";
    urlsOnly.forEach(function(url)
    {
        if (!~url.indexOf("[/url]")) {
            _overview += url;
        }
        else {

            let urls2 = [];
            urls2 = url.split("[/url]");

            _overview += "<a target='_blank' rel='noopener noreferrer' href='" + urls2[0] + "'>" + urls2[0] + "</a>";
            for (let i = 1; i < urls2.length; i++)
            {
                _overview += urls2[i];
            }


        }

    });

    return _overview;
}