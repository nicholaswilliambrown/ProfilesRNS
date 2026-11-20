
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
                <button class="link-ish" id="toDivMapDataText">click here.</button></div>
        </div>
        <div id="divMapDataText">
            To return to the map, <button class="toDivMap link-ish">click here.</button>
            <div id="mapTextInner" class="mt-2 mb-2"></div>
            To return to the map, <button class="toDivMap link-ish">click here.</button>
        </div>
    </div>
</div>
`;

function mapParse(moduleJson, indicatedLabel, target) {
    if (!target) {
        target = $('#topLhsDiv');
    }
    if ($('#moveableContent').length == 0) {
        target.append(gMapTab.commonHtml);
    }

    if (indicatedLabel) {
        $('#mapRedBoldIndicated').html(indicatedLabel);
    }

    initPageWithMap(moduleJson);

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
function initPageWithMap(moduleJson) {
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
        let averageLatArray = gMapTab.people.map(p => p.latitude).filter(l => l !== undefined );
        let averageLongArray = gMapTab.people.map(p => p.longitude).filter(l => l !== undefined );

        let averageLat = arrayAverage(averageLatArray, 42.33735);
        let averageLong = arrayAverage(averageLongArray, -71.10335);
        centerLatLong = {lat: averageLat,
                        long: averageLong};
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
function makeLatLongString(lat, long) {
    let result = '';
    if (lat && long) {
        result = JSON.stringify({latitude: lat, longitude: long})
    }
    return result;
}
function createPeopleAtLocationMap() {
    let mapPeopleToLocation = new Map();
    for (let i=0; i<gMapTab.people.length; i++) {
        let thePerson = gMapTab.people[i];
        addPersonToLocationMap(thePerson, mapPeopleToLocation);
    }
    return mapPeopleToLocation;
}
function addPersonToLocationMap(thePerson, peopleAtLocation) {
    let personsLocation = makeLatLongString(thePerson.latitude, thePerson.longitude);
    let peopleThere = peopleAtLocation.get(personsLocation);
    let personRecord = {
        display_name: thePerson.display_name,
        URI: thePerson.URI,
        address1: thePerson.address1,
        address2: thePerson.address2,
        latitude: thePerson.latitude,
        longitude: thePerson.longitude
    };
    if (!peopleThere) {
        peopleAtLocation.set(personsLocation, [personRecord])
    }
    else {
        peopleThere.push(personRecord);
    }
}

// maybe DB should handle this?
function getPopularUnnamedInfo(peopleInfo) {
    function myTrim(address) {
        return address.trim().replace(/\s+/g, " ");
    }
    let address1Map = new Map();
    for (let i=0; i<peopleInfo.length; i++) {
        let trimmedAddress1 = myTrim(peopleInfo[i].address1);
        peopleInfo[i].address1 = trimmedAddress1;

        let currentCount = address1Map.get(trimmedAddress1);
        let newCount = currentCount ? 1 + currentCount : 1;
        address1Map.set(trimmedAddress1, newCount);
    }
    address1Map = new Map([...address1Map.entries()].sort((a, b) => b[1] - a[1]));
    let sortedKeysArray = [...address1Map.keys()];

    let popularUnnamedInfo = peopleInfo.find(pi => pi.address1 = sortedKeysArray[0]);

    return popularUnnamedInfo;
}
function pinPopupContent(peopleInfo) {
    let popupDiv = $('<div></div>');

    for (let i=0; i<peopleInfo.length; i++) {
        let thePerson = peopleInfo[i];
        if (i == 0) {
            popupDiv.append($(`<div class="fw-bold mapPopLine mapPopLine1">${escapeHTML(thePerson.address1)}</div>`));
        }

        let url = thePerson.URI;
        popupDiv.append($(`<div class="mapPopLine mapPopLine3"><a href="${escapeHTML(safeUrl(url))}">${escapeHTML(thePerson.display_name)}</a></div>`));
    }

    let result = popupDiv[0];
    return result;
}

function googleMapLoadData(callback) {
    // create markers for people
    let peopleAtLocationMap = createPeopleAtLocationMap();

    let markers = [];
    let palKeys = [...peopleAtLocationMap.keys()];
    for (let i=0; i<palKeys.length; i++) {
        let theLocation = palKeys[i];
        let locationsPeopleInfo = peopleAtLocationMap.get(theLocation);

        // all map keys here should lead to at least one person
        let wlogPersonInfo = locationsPeopleInfo[0];
        let pin = new google.maps.Marker({
                position: new google.maps.LatLng(wlogPersonInfo.latitude, wlogPersonInfo.longitude),
                title: `${wlogPersonInfo.address1},${wlogPersonInfo.address2}`
            });
        markers.push(pin);
        theLocation.pin = pin; // save reference to data array

        // drop animation
        setTimeout(() => pin.setMap(gMapTab.gmap), 100 * i);

        // save reference to data array
        theLocation.pin = pin;

        // click event handler
        google.maps.event.addListener(pin, 'click', function() {
            mapClickLocation(this, locationsPeopleInfo);
        });
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

function mapClickLocation(that, peopleInfo) {
    // This function is called when the user clicks on a marker
    let popupContent = pinPopupContent(peopleInfo);

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

        // for some maps, address1 has person count tacked on
        let address1 = conn.address1.replace(/\(\d+ People\)/, '').replace('(1 Person)', '');

        // for some maps, address2 is just a person count
        let address2 = conn.address2.match(/\(\d+ People\)/) ? '' : conn.address2;
        address2 = address2.match(/\(1 Person\)/) ? '' : address2;

        let address = $('<div class="align-left"></div>');
        address.append($(`<div>${escapeHTML(address1)}</div>`));
        address.append($(`<div>${escapeHTML(address2)}</div>`));

        let latitude = conn.latitude;
        let longitude = conn.longitude;

        let url = conn.URI;
        let name = conn.display_name;
        let nameUrl = createAnchorElement(name, url);

        let rowId = `details-${i}`;
        row = makeRowWithColumns(target, rowId, colspecs, `ms-1 borderOneSolid ${stripeClass}`);

        row.find(`#${rowId}Col0`).append(address);
        row.find(`#${rowId}Col1`).html(escapeHTML(latitude));
        row.find(`#${rowId}Col2`).html(escapeHTML(longitude));
        row.find(`#${rowId}Col3`).append(nameUrl);
    }
}


