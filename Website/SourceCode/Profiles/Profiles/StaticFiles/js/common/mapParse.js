
function trivialCallback() {} // required for google.maps

gMapTab.commonHtml = `
<div id="moveableContent">
    <div id="litGoogleCode" runat="server"></div>
    <div>
        <div id="divMapData">
            <div class="alignLeft">
                <span class="boldRed">Red markers</span>
                indicate the 
                <span id="mapRedBoldIndicated">co-authors.</span>.
                <br/>
                <span class="boldBlue">Blue lines</span>
                    connect people who have published papers together.
                <div ID="lblPerson" runat="server"></div>
            </div>
            <hr class="tightHr"/>
            <div class="alignLeft mb-1">
                <b>Zoom</b>:&nbsp;
                <span class="link-ish" id="zoomNewEngland">New England</span> |
                <span class="link-ish" id="zoomBoston">Boston</span> |
                <span class="link-ish" id="zoomLongwood">Longwood</span>
            </div>
            <div id="map_canvas">
            </div>
            <br/>
            <div class="alignLeft">To see the data from this visualization as text,
                <a class="link-ish" id="toDivMapDataText">click here.</a></div>
        </div>
        <div id="divMapDataText">
            To return to the map, <a class="toDivMap link-ish">click here.</a>
            <div id="mapTextInner" class="mt-2 mb-2"></div>
            To return to the map, <a class="toDivMap link-ish">click here.</a>
        </div>
    </div>
</div>
`;

async function mapParse(moduleJson, embedded, indicatedLabel) {
    let topLhsDiv = $('#topLhsDiv');
    topLhsDiv.append(gMapTab.commonHtml);
    $('#mapRedBoldIndicated').html(indicatedLabel);

    await initPage(moduleJson, embedded);

    $('#zoomLongwood').on("click",
        function() { zoomToCoords(gMapTab.longwoodCoords)});
    $('#zoomBoston').on("click",
        function() { zoomToCoords(gMapTab.bostonCoords)});
    $('#zoomNewEngland').on("click",
        function() { zoomToCoords(gMapTab.newEnglandCoords)});

    $('#toDivMapDataText').on("click",
        function() {
            $('#divMapDataText').show();
            $('#divMapData').hide();
        });

    $('.toDivMap').on("click",
        function() {
            $('#divMapData').show();
            $('#divMapDataText').hide();
        });

    parseTextVersion(moduleJson);
}

function zoomToCoords(coords) {
    gMapTab.gmap.setZoom(coords.zoom);
    gMapTab.gmap.setCenter({
        lat: coords.latitude,
        lng: coords.longitude
    });
}

// see NetworkMap.ascx and/or NetworkMapList.ascx
async function initPage(moduleJson, embedded) {
    if ( ! embedded) {
        embedded = false; // explicit falsiness
    }

    gMapTab.newEnglandCoords = {
        zoom: 7,
        latitude: 42.354637,
        longitude: -71.089168
    };
    gMapTab.bostonCoords = {
        zoom: 13,
        latitude: 42.337526,
        longitude: -71.089168
    };
    gMapTab.longwoodCoords = {
        zoom: 16,
        latitude: 42.337526,
        longitude: -71.104536
    };

    gMapTab.people = embedded ?
                            moduleJson.ModuleData[0].people :
                            moduleJson.people;
    gMapTab.connections = embedded ?
        moduleJson.ModuleData[0].connections :
        moduleJson.connections;

    let mainPersonUri = personUriFromUrlPath();
    // bug: p.URI might have double-slash
    let mainPerson = gMapTab.people.find(p => (p.URI.replace("//", "/")) == mainPersonUri);

    gMapTab.mapCenter = new google.maps.LatLng(
        mainPerson.latitude, mainPerson.longitude);

    let goptions = {
        zoom: 13,
        center: gMapTab.mapCenter,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };

    // create google map object
    gMapTab.gmap = new google.maps.Map(document.getElementById("map_canvas"), goptions);

    // create our info window object
    gMapTab.ginfowindow = new google.maps.InfoWindow;

    // load the points in a second (allow map render)
    setTimeout(mapLoadData, 500);
}

function mapPinPopupContent(thePerson) {
    let popupDiv = $('<div></div>');

    let url = `${thePerson.URI}`;

    popupDiv.append($(`<div class="mapPopLine mapPopLine1">${thePerson.address1}</div>`));
    popupDiv.append($(`<div class="mapPopLine mapPopLine2">${thePerson.address2}</div>`));
    popupDiv.append($(`<div class="mapPopLine mapPopLine3"><a href="${url}">${thePerson.display_name}</a></div>`));

    let result = popupDiv[0];
    return result;
}
function mapClickLocation(that, thePerson) {
    // This function is called when the user clicks on a marker
    let popupContent = mapPinPopupContent(thePerson);

    gMapTab.ginfowindow.setContent(popupContent);
    gMapTab.ginfowindow.open(gMapTab.gmap, that);
}
function mapLoadData(callback) {
    // create markers for people
    for (var i = 0; i < gMapTab.people.length; i++) {
        let thePerson = gMapTab.people[i];
        if (typeof thePerson.pin === "undefined") {
            let pin = new google.maps.Marker({
                position: new google.maps.LatLng(thePerson.latitude, thePerson.longitude),
                title: thePerson.display_name,
            });

            // click event handler
            pin.addListener('click', function () {
                mapClickLocation(this, thePerson)
            });

            // drop animation
            setTimeout("gMapTab.people[" + i + "].pin.setMap(gMapTab.gmap);", 100 * i);

            // save reference to data array
            thePerson.pin = pin;
        }
    }
    // create network lines
    for (let i = 0; i < gMapTab.connections.length; i++) {
        let connection = gMapTab.connections[i];
        if ( ! connection.overlay) {
            let conOptions = {
                map: gMapTab.gmap,
                strokeOpacity: 0.5,
                path: [new google.maps.LatLng(connection.x1, connection.y1),
                    new google.maps.LatLng(connection.x2, connection.y2)],
                strokeColor: '#0000FF',
                strokeWeight: 2
            };
            // save back to data array
            connection.overlay = new google.maps.Polyline(conOptions);
        }
    }
}
function parseTextVersion(moduleJson) {

    let jsonData = gMapTab.people;
    let target = $('#mapTextInner');

    let colspecs = [
        newColumnSpec(`${gCommon.cols7or12} alignMiddle bordE`),
        newColumnSpec(`${gCommon.cols1or12} alignMiddle bordE d-flex justify-content-center`),
        newColumnSpec(`${gCommon.cols1or12} alignMiddle bordE d-flex justify-content-center`),
        newColumnSpec(`${gCommon.cols3or12} alignMiddle bordE d-flex justify-content-center`)
    ];

    let rowId = `mapTextTable`;
    let row = makeRowWithColumns(target, rowId, colspecs, "borderOneSolid stripe");

    row.find(`#${rowId}Col0`).html('<strong>Address</strong>');
    row.find(`#${rowId}Col1`).html('<strong>Latitude</strong>');
    row.find(`#${rowId}Col2`).html('<strong>Longitude</strong>');
    row.find(`#${rowId}Col3`).html('<strong>Names</strong>');

    let numItems = jsonData.length;
    for (let i=0; i<numItems; i++) {
        let conn = jsonData[i];
        let stripeClass = (i%2 == 1) ? "stripe" : "";

        let address = $('<div class="align-left"></div>');
        address.append($(`<div>${conn.address1}</div>`));
        address.append($(`<div>${conn.address2}</div>`));

        let latitude = conn.latitude;
        let longitude = conn.longitude;

        // Urls in the form of display/person/xxxx are favored, /profile/pid deprecated
        let url = `${conn.URI}`;
        let name = conn.display_name;
        let nameUrl = createAnchorElement(name, url);

        let rowId = `details-${i}`;
        row = makeRowWithColumns(target, rowId, colspecs, `ms-1 borderOneSolid ${stripeClass}`);

        row.find(`#${rowId}Col0`).append(address);
        row.find(`#${rowId}Col1`).html(latitude);
        row.find(`#${rowId}Col2`).html(longitude);
        row.find(`#${rowId}Col3`).append(nameUrl);
    }
}


