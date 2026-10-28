
function setupLeafletMap(centerLat, centerLong, zoom) {
    gMapTab.lMap = L.map('map_canvas').setView([centerLat, centerLong], zoom);

    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(gMapTab.lMap);

    $('.leaflet-control-attribution').find('svg').remove();
}
function leafletMapLoadData() {
    pruneMissingLatLongs();

    leafletMapLoadPins();
    leafletMapLoadLines();

    $('.redMarker').removeClass('boldRed').addClass('leafletRed');
    zoomToCoords(gMapTab.bostonCoords);
}
function pruneMissingLatLongs() {
    // filter people from (0,0), (null,null) and such
    let uncoordinatedIds = gMapTab.people.filter(p => !(p.latitude && p.longitude)).map(p => p.PersonID);
    gMapTab.people = gMapTab.people.filter(p => p.latitude && p.longitude);
    gMapTab.connections = gMapTab.connections.filter(c => ! (uncoordinatedIds.includes(c.a) || uncoordinatedIds.includes(c.b)));
}
function leafletPinPopupContent(thePeople) {
    let popupDiv = $('<div></div>');

    for (let i=0; i<thePeople.length; i++) {
        let thePerson = thePeople[i];
        if (i == 0) {
            popupDiv.append($(`<div class="fw-bold mapPopLine mapPopLine1">${thePerson.address1},${thePerson.address2}</div>`));
        }

        let url = thePerson.URI;
        popupDiv.append($(`<div class="mapPopLine mapPopLine3"><a href="${url}">${thePerson.display_name}</a></div>`));
    }

    let result = popupDiv[0];
    return result;
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
function leafletMapLoadPins() {
    // create pins/markers for people based on locations

    let peopleAtLocation = new Map();
    for (var i = 0; i < gMapTab.people.length; i++) {
        let thePerson = gMapTab.people[i];
        addPersonToLocationMap(thePerson, peopleAtLocation);
    }
    let markers = [];
    for (let theLocation of peopleAtLocation.keys()) {
            let peopleInfo = peopleAtLocation.get(theLocation);

            let onePersonInfo = {};
            let collectiveTitleList = [];
            for (let i=0; i<peopleInfo.length; i++) {
                onePersonInfo = peopleInfo[i];
                collectiveTitleList.push(onePersonInfo.display_name);
            }
            let collectiveTitle = collectiveTitleList.join(';');
            let pin = L.marker([onePersonInfo.latitude, onePersonInfo.longitude],
                {title: `${onePersonInfo.address1},${onePersonInfo.address2}`});
            markers.push(pin);

            let popupContent = leafletPinPopupContent(peopleInfo);
            pin.bindPopup(popupContent);
            theLocation.pin = pin; // save reference to data array

            // drop animation
            setTimeout(() => pin.addTo(gMapTab.lMap), 100 * i);
    }
    let pinGroup = new L.featureGroup(markers);
    let bounds = pinGroup.getBounds();
    gMapTab.lMap.fitBounds(bounds);
}
function leafletMapLoadLines() {
    // create network lines
    for (let i = 0; i < gMapTab.connections.length; i++) {
        let connection = gMapTab.connections[i];
        if ( ! connection.overlay) {
            let latlngs = [
                    [connection.x1, connection.y1],
                    [connection.x2, connection.y2]
                ];
            let line = L.polyline(latlngs, {color:'blue'}).addTo(gMapTab.lMap);
            // save back to data array
            connection.overlay = line;
        }
    }
}
