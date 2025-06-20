
function trivialCallback() {} // required for google.maps

gMapTab.commonHtml = `
<div id="moveableContent">
    <div id="litGoogleCode" runat="server"></div>
    <div>
        <div id="divMapData">
            <div class="alignLeft">
                <span class="redMarker boldRed">Red markers</span>
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

async function mapParse(moduleJson, indicatedLabel) {
    let topLhsDiv = $('#topLhsDiv');
    topLhsDiv.append(gMapTab.commonHtml);

    if (indicatedLabel) {
        $('#mapRedBoldIndicated').html(indicatedLabel);
    }

    await initPage(moduleJson);

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
    if (g.mapProvider == g.mapProviderOptions.google) {

        gMapTab.gmap.setZoom(coords.zoom);
        gMapTab.gmap.setCenter({
            lat: coords.latitude,
            lng: coords.longitude
        });
    }
    else { // leaflet
        gMapTab.lMap.setView([coords.latitude, coords.longitude], coords.zoom);
    }
}

// see NetworkMap.ascx and/or NetworkMapList.ascx
async function initPage(moduleJson) {
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

    // how deep is the data that we passed in?
    let dataContainer = moduleJson;
    if (moduleJson.ModuleData) {
        dataContainer = moduleJson.ModuleData;
    }
    gMapTab.people = dataContainer.people;
    gMapTab.connections = dataContainer.connections;

    let mainPersonUri = getPersonUriFromLabel();

    let centralPerson = gMapTab.people.find(p => p.URI == mainPersonUri);

    let centerLatLong;
    if (centralPerson) {
        centerLatLong = {lat: centralPerson.latitude, long:centralPerson.longitude};
    }
    else {
        let averageLatArray = gMapTab.people.map(p => p.latitude);
        let averageLongArray = gMapTab.people.map(p => p.longitude);

        centerLatLong = {lat: arrayAverage(averageLatArray),
                        long: arrayAverage(averageLongArray)};
    }

    gMapTab.initialZoom = 13;

    if (g.mapProvider == g.mapProviderOptions.google) {
        let mapCenter = new google.maps.LatLng(
            centerLatLong.lat, centerLatLong.long);

        let goptions = {
            zoom: gMapTab.initialZoom,
            center: mapCenter,
            mapTypeId: google.maps.MapTypeId.ROADMAP
        };
        // create google map object
        gMapTab.gmap = new google.maps.Map(document.getElementById("map_canvas"), goptions);

        // create google's info window object
        gMapTab.ginfowindow = new google.maps.InfoWindow;

        // load the points in a second (allow map render)
        setTimeout(googleMapLoadData, g.mapProviderOptions.googleLoadingDelay);
    }
    else { // leaflet
        setupLeafletMap(centerLatLong.lat, centerLatLong.long, gMapTab.initialZoom);

        // load the points in a second (allow map render)
        setTimeout(leafletMapLoadData, g.mapProviderOptions.leafletLoadingDelay);
    }
}
function googleMapLoadData(callback) {
    // create markers for people
    for (var i = 0; i < gMapTab.people.length; i++) {
        let thePerson = gMapTab.people[i];
        if (typeof thePerson.pin === "undefined") {
            // deprecation warning says to use google.maps.marker.AdvancedMarkerElement,
            //   but we probably need a new api key when loading, since the version of maps
            //   we now get does not know about AdvancedMarkerElement
            let pin = new google.maps.Marker({
                position: new google.maps.LatLng(thePerson.latitude, thePerson.longitude),
                title: thePerson.display_name,
            });

            // drop animation
            setTimeout("gMapTab.people[" + i + "].pin.setMap(gMapTab.gmap);", 100 * i);

            // save reference to data array
            thePerson.pin = pin;

            // click event handler
            google.maps.event.addListener(pin, 'click', function() {
                mapClickLocation(this, thePerson)
            });
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

function mapPinPopupContent(thePerson) {
    let popupDiv = $('<div></div>');

    let url = thePerson.URI;

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
    let row = makeRowWithColumns(target, rowId, colspecs, "borderOneSolid tableHeaderPagingRow");

    row.find(`#${rowId}Col0`).html('<strong>Address</strong>');
    row.find(`#${rowId}Col1`).html('<strong>Latitude</strong>');
    row.find(`#${rowId}Col2`).html('<strong>Longitude</strong>');
    row.find(`#${rowId}Col3`).html('<strong>Names</strong>');

    let numItems = jsonData.length;
    for (let i=0; i<numItems; i++) {
        let conn = jsonData[i];
        let stripeClass = (i % 2 == 1) ? "tableOddRowColor" : "";

        let address = $('<div class="align-left"></div>');
        address.append($(`<div>${conn.address1}</div>`));
        address.append($(`<div>${conn.address2}</div>`));

        let latitude = conn.latitude;
        let longitude = conn.longitude;

        let url = conn.URI;
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


