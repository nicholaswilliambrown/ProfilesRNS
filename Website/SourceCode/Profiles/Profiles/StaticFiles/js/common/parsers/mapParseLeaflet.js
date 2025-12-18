
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
    // create pins/markers for people
    let markers = [];
    for (var i = 0; i < gMapTab.people.length; i++) {
        let thePerson = gMapTab.people[i];
        if (typeof thePerson.pin === "undefined") {
            let pin = L.marker([thePerson.latitude, thePerson.longitude],
                {title: thePerson.display_name});
            markers.push(pin);

            let popupContent = mapPinPopupContent(thePerson);
            pin.bindPopup(popupContent);
            thePerson.pin = pin; // save reference to data array

            // drop animation
            setTimeout("gMapTab.people[" + i + "].pin.addTo(gMapTab.lMap);", 100 * i);
        }
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
