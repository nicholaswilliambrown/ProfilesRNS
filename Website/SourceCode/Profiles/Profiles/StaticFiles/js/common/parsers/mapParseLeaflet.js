
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

function leafletMapLoadPins() {
    // create pins/markers for people based on locations
    let peopleAtLocationMap = getPeopleAtLocationMap();

    let markers = [];
    let palKeys = [...peopleAtLocationMap.keys()];
    for (let i=0; i<palKeys.length; i++) {
        let theLocation = palKeys[i];
        let peopleInfo = peopleAtLocationMap.get(theLocation);

        let onePersonInfo = {};
        let collectiveTitleList = [];
        for (let j=0; j<peopleInfo.length; j++) {
            onePersonInfo = peopleInfo[j];
            collectiveTitleList.push(onePersonInfo.display_name);
        }
        let pin = L.marker([onePersonInfo.latitude, onePersonInfo.longitude],
            {title: `${onePersonInfo.address1},${onePersonInfo.address2}`});
        markers.push(pin);

        let popupContent = pinPopupContent(peopleInfo);
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
