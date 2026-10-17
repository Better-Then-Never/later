/// Map looks per theme.
///
/// Light mode keeps the cloud style of the Later map ID (Google Cloud Console
/// "Map Management"), which has no dark variant on Android. Dark mode draws
/// the map without the map ID and with [dark]: the same idea as the light
/// style (blue water, green parks, quiet roads) on the dark palette, so the
/// map does not glare next to the dark interface. Made with the Google map
/// style format (https://mapstyle.withgoogle.com/).
abstract final class MapStyles {
  static const dark = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1c1c1c"}]},
  {"elementType": "labels.icon", "stylers": [{"saturation": -60}, {"lightness": -30}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#9a9a9a"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#141414"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#3a3a3a"}]},
  {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#b4b4b4"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#d6d6d6"}]},
  {"featureType": "administrative.neighborhood", "elementType": "labels.text.fill", "stylers": [{"color": "#8c8c8c"}]},
  {"featureType": "landscape.man_made", "elementType": "geometry", "stylers": [{"color": "#212121"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#1d231c"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#232323"}]},
  {"featureType": "poi", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#1e3a1c"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2e2e2e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#1a1a1a"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8c8c8c"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#333333"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3d3d3d"}]},
  {"featureType": "road.highway.controlled_access", "elementType": "geometry", "stylers": [{"color": "#464646"}]},
  {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#6e6e6e"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2a2a2a"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#8c8c8c"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#12304f"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#5f87b0"}]},
  {"featureType": "water", "elementType": "labels.text.stroke", "stylers": [{"color": "#12304f"}]}
]
''';
}
