/// Map looks per theme, both local styles in the Google map style format
/// (https://mapstyle.withgoogle.com/): blue water, green parks, quiet roads.
///
/// The light look used to be the cloud style of the Later map ID. A map ID
/// cannot change after the map is created and the dark style must not have
/// it, so every theme switch recreated the map (22 ms frame, a crash path;
/// docs/feel/PERFORMANCE.md). With two local styles the map restyles in
/// place. [light] follows the cloud style's idea (F-15, DECISIONS.md).
abstract final class MapStyles {
  static const light = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#f3f3f0"}]},
  {"elementType": "labels.icon", "stylers": [{"saturation": -40}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#5f6368"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#ffffff"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#cfcfcf"}]},
  {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#4a4a4a"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#333333"}]},
  {"featureType": "administrative.neighborhood", "elementType": "labels.text.fill", "stylers": [{"color": "#8a8a8a"}]},
  {"featureType": "landscape.man_made", "elementType": "geometry", "stylers": [{"color": "#eeeeeb"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#e6f0de"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#ececea"}]},
  {"featureType": "poi", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#c9e9b6"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#ffffff"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#e2e2e2"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#7a7a7a"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#f6f6f6"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#d9d9d9"}]},
  {"featureType": "road.highway.controlled_access", "elementType": "geometry", "stylers": [{"color": "#ececec"}]},
  {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#9a9a9a"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#e6e6e6"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#7a7a7a"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#a9d3f2"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3f74a8"}]},
  {"featureType": "water", "elementType": "labels.text.stroke", "stylers": [{"color": "#a9d3f2"}]}
]
''';

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
