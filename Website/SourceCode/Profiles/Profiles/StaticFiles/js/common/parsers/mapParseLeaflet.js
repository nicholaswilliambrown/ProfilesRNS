
function setupLeafletMap(centerLat, centerLong, zoom) {
    if (gMapTab.lMap) {
        gMapTab.lMap.remove();
    }
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
    function nullOrUndef(coord) {
        return coord === undefined || coord == null;
    }

    // filter people from (null,null) and such
    gMapTab.unMappedPeople = gMapTab.people.filter(
        p => nullOrUndef(p.latitude) || nullOrUndef(p.longitude));
    gMapTab.people =         gMapTab.people.filter(
        p => !nullOrUndef(p.latitude) && !nullOrUndef(p.longitude));

    let mappablePersonIds = gMapTab.people.map(p => p.PersonID);
    gMapTab.connections = gMapTab.connections.filter(
        c => mappablePersonIds.includes(c.a) && mappablePersonIds.includes(c.b));
}

function leafletMapLoadPins() {
    // create pins/markers for people based on locations
    let peopleAtLocationMap = createPeopleAtLocationMap();

    let markers = [];
    let PALkeys = [...peopleAtLocationMap.keys()];
    for (let i=0; i<PALkeys.length; i++) {
        let theLocation = PALkeys[i];
        let locationsPeopleInfo = peopleAtLocationMap.get(theLocation);

        let popularUnnamedInfo = getPopularUnnamedInfo(locationsPeopleInfo);

        let pin = L.marker([popularUnnamedInfo.latitude, popularUnnamedInfo.longitude],
            {title: `${popularUnnamedInfo.address1}. ${popularUnnamedInfo.address2}`});
        markers.push(pin);

        let popupContent = pinPopupContent(locationsPeopleInfo);
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
