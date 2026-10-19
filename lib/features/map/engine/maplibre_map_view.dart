part of '../map_page.dart';

/// The map drawn by MapLibre (docs/map/DECISION.md), behind
/// [FeatureFlags.mapLibre]: the heat, the bubbles and the pins are layers of
/// the map itself, drawn on the GPU, their look a function of the zoom the map
/// evaluates every frame ([MapZoomVisuals]). The capsules are grouped here
/// ([_GroupStage]): their bubbles split and merge as the zoom passes half
/// levels, the moving pieces sent to the map frame by frame. The buttons, the
/// card and the hint are the Google map page's.
class MapLibreMapView extends StatefulWidget {
  const MapLibreMapView({super.key});

  @override
  State<MapLibreMapView> createState() => _MapLibreMapViewState();
}

/// Layer and source ids.
const _capsulesSource = 'capsules';
const _heatSource = 'capsules_heat';
const _meSource = 'me';
const _selectedSource = 'selected';
const _heatLayer = 'heat';
const _pinsLayer = 'pins';
const _bubblesLayer = 'bubbles';
const _meLayer = 'me';
const _shadowLayer = 'selected_shadow';
const _selectedLayer = 'selected_pin';

/// For tuning on the phone (debug): start at this zoom.
final double? _debugZoom = double.tryParse(
  const String.fromEnvironment('MAP_START_ZOOM'),
);

/// Layer properties sent as they are: the plugin's own classes send every
/// property, unset ones as null, which would reset them.
class _Props implements ml.LayerProperties {
  const _Props(this.json);

  final Map<String, dynamic> json;

  @override
  Map<String, dynamic> toJson({bool skipNulls = true}) => json;
}

class _MapLibreMapViewState extends State<MapLibreMapView>
    with TickerProviderStateMixin {
  ml.MapLibreMapController? _controller;
  final _ready = Completer<ml.MapLibreMapController>();
  bool _styled = false;
  bool? _styleDark;
  int? _dataVersion;
  GeoPosition? _meAt;
  late final MapFocus _focus;
  final _bearing = ValueNotifier<double>(0);
  double _zoom = 0;
  bool _reportedLocationProblem = false;

  /// "Leave your first capsule" closed on this phone (as on the Google page).
  bool _hintClosed = true;

  /// Where the map was when it last stopped (this phone, this account): a
  /// cold start opens there at once, before any location fix (M-06).
  ml.CameraPosition? _savedCamera;
  bool _cameraRead = false;
  String? _cameraSaved;

  // Fingers and camera, for MapStats.
  int _pointers = 0;
  bool _moving = false;

  /// The capsule whose card is open, and its pin's motion (M-02): it jumps,
  /// sways and hovers as a layer of its own ([_selectedLayer]), moved by its
  /// paint (no new pictures, nothing else re-laid out).
  Capsule? _selected;
  Capsule? _shown;
  final _motion = PinMotion();
  late final Ticker _ticker = createTicker(_tick);
  late final _stage = _GroupStage(vsync: this);
  Duration _last = Duration.zero;
  int _sentAt = -1000;

  @override
  void initState() {
    super.initState();
    // A TextureView composed by Flutter (TLHC): with the default SurfaceView
    // Flutter fell back to hybrid composition, its frames 3x slower to draw.
    ml.MapLibreMap.useHybridComposition = true;
    MapStats.instance.watchFrames();
    if (MapStats.flashProbe) unawaited(_FlashProbe(this).run());
    _focus = context.read<MapFocus>()..addListener(_onFocusRequested);
    selectedPageNotifier.addListener(_onTabChanged);
    unawaited(_loadHint());
    unawaited(_loadCamera());
  }

  Future<void> _loadCamera() async {
    final uid = context.read<SessionController>().uid;
    final saved = uid == null
        ? null
        : await context.read<PreferencesStore>().string(
            uid,
            MapCameraMemory.key,
          );
    if (!mounted) return;
    setState(() {
      if (MapCameraMemory.parse(saved) case (final lat, final lng, final z)) {
        _savedCamera = ml.CameraPosition(target: ml.LatLng(lat, lng), zoom: z);
      }
      _cameraRead = true;
    });
  }

  void _saveCamera(ml.CameraPosition camera) {
    final uid = context.read<SessionController>().uid;
    if (uid == null) return;
    final value = MapCameraMemory.format(
      camera.target.latitude,
      camera.target.longitude,
      camera.zoom,
    );
    if (value == _cameraSaved) return;
    _cameraSaved = value;
    unawaited(
      context.read<PreferencesStore>().setString(
        uid,
        MapCameraMemory.key,
        value,
      ),
    );
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusRequested);
    selectedPageNotifier.removeListener(_onTabChanged);
    _ticker.dispose();
    _stage.dispose();
    _bearing.dispose();
    super.dispose();
  }

  Future<void> _loadHint() async {
    final uid = context.read<SessionController>().uid;
    if (uid == null) return;
    final closed =
        await context.read<PreferencesStore>().string(
          uid,
          _MapViewState._hintKey,
        ) ==
        'closed';
    if (mounted && !closed) setState(() => _hintClosed = false);
  }

  void _closeHint() {
    setState(() => _hintClosed = true);
    final uid = context.read<SessionController>().uid;
    if (uid != null) {
      unawaited(
        context.read<PreferencesStore>().setString(
          uid,
          _MapViewState._hintKey,
          'closed',
        ),
      );
    }
  }

  void _onTabChanged() {
    if (selectedPageNotifier.value != AppTabs.map) _select(null);
  }

  void _active() => MapStats.instance.active.value = _pointers > 0 || _moving;

  // For the flash probe (MAP_FLASH): whether anything moves, what was sent,
  // and the layers that draw pins and bubbles.
  bool get _busy =>
      _pointers > 0 || _moving || _stage.animating || _ticker.isActive;
  _Sent? _sentSelected;
  Map<String, _Sent> _sentMarkers() => {
    ..._stage.sentStill,
    ..._stage.sentMoving,
    if (_sentSelected case final s?) ?_shown?.id: s,
  };
  List<String> get _markerLayers => const [
    _pinsLayer,
    _bubblesLayer,
    _movingPinsLayer,
    _movingBubblesLayer,
    _selectedLayer,
  ];

  // ---------------------------------------------------------------- style

  Future<void> _onStyleLoaded() async {
    final c = _controller;
    if (c == null || !mounted) return;
    final map = context.read<MapController>();
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final images = await MapLibreImages.all(ratio: ratio, dark: dark);
    for (final MapEntry(:key, :value) in images.entries) {
      await c.addImage(key, value);
    }
    // The data as read here: capsules that arrive while the layers are being
    // added are sent by [_syncData] once the style is ready.
    final version = map.capsulesVersion;
    final me = map.myPosition;
    // Empty first, filled as a string (_setSource): off the main thread.
    await c.addGeoJsonSource(_heatSource, _features(const []));
    // Pins and bubbles: grouped by [_GroupStage], still and moving.
    await c.addGeoJsonSource(_capsulesSource, _features(const []));
    await c.addGeoJsonSource(_movingSource, _features(const []));
    await c.addGeoJsonSource(_meSource, _point(me));
    await c.addGeoJsonSource(_selectedSource, _features(const []));
    await c.addHeatmapLayer(
      _heatSource,
      _heatLayer,
      ml.HeatmapLayerProperties(
        heatmapWeight: 1,
        heatmapIntensity: MapZoomVisuals.heatIntensityExpression(),
        heatmapRadius: MapZoomVisuals.heatRadiusExpression(),
        heatmapOpacity: MapZoomVisuals.heatOpacityExpression(),
        // Cool to warm, the app's own colours (the Google map's ramp, M-11).
        heatmapColor: const [
          'interpolate',
          ['linear'],
          ['heatmap-density'],
          0,
          'rgba(33,150,243,0)',
          0.02,
          'rgba(33,150,243,0.12)',
          0.1,
          'rgba(86,201,46,0.22)',
          0.4,
          'rgba(255,217,0,0.29)',
          0.8,
          'rgba(255,152,0,0.35)',
        ],
      ),
      maxzoom: MapZoomVisuals.heatTo + 0.1,
    );
    final opacity = MapZoomVisuals.markerOpacityExpression();
    await c.addSymbolLayer(
      _capsulesSource,
      _pinsLayer,
      ml.SymbolLayerProperties(
        iconImage: const ['get', 'image'],
        iconAnchor: 'bottom',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: opacity,
      ),
      filter: _pinsFilter(_shown?.id),
    );
    await c.addSymbolLayer(
      _capsulesSource,
      _bubblesLayer,
      ml.SymbolLayerProperties(
        iconImage: const ['get', 'image'],
        // Bigger for more capsules: a clear scale by count.
        iconSize: const [
          'interpolate',
          ['linear'],
          ['get', 'count'],
          2,
          0.9,
          10,
          1.0,
          50,
          1.12,
          200,
          1.25,
        ],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: opacity,
        // The bigger bubbles on top.
        symbolSortKey: const ['get', 'count'],
      ),
      filter: const [
        '==',
        ['get', 'kind'],
        'bubble',
      ],
    );
    // The pieces that move while bubbles split and merge, over the still
    // ones, each with its own size and opacity.
    final moving = MapZoomVisuals.markerOpacityExpression(
      times: const ['get', 'opacity'],
    );
    await c.addSymbolLayer(
      _movingSource,
      _movingPinsLayer,
      ml.SymbolLayerProperties(
        iconImage: const ['get', 'image'],
        iconAnchor: 'bottom',
        iconSize: const ['get', 'scale'],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: moving,
      ),
      filter: const [
        '==',
        ['get', 'kind'],
        'pin',
      ],
      enableInteraction: false,
    );
    await c.addSymbolLayer(
      _movingSource,
      _movingBubblesLayer,
      ml.SymbolLayerProperties(
        iconImage: const ['get', 'image'],
        iconSize: const [
          '*',
          [
            'interpolate',
            ['linear'],
            ['get', 'count'],
            2,
            0.9,
            10,
            1.0,
            50,
            1.12,
            200,
            1.25,
          ],
          ['get', 'scale'],
        ],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: moving,
        symbolSortKey: const ['get', 'count'],
      ),
      filter: const [
        '==',
        ['get', 'kind'],
        'bubble',
      ],
      enableInteraction: false,
    );
    await c.addSymbolLayer(
      _selectedSource,
      _shadowLayer,
      const ml.SymbolLayerProperties(
        iconImage: 'shadow',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: 0,
      ),
      enableInteraction: false,
    );
    await c.addSymbolLayer(
      _selectedSource,
      _selectedLayer,
      const ml.SymbolLayerProperties(
        iconImage: [
          'concat',
          'pin_selected_',
          ['get', 'color'],
        ],
        iconAnchor: 'bottom',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      enableInteraction: false,
    );
    await c.addSymbolLayer(
      _meSource,
      _meLayer,
      const ml.SymbolLayerProperties(
        iconImage: 'me',
        iconAnchor: 'bottom',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      enableInteraction: false,
    );
    _dataVersion = version;
    _meAt = me;
    _stage
      ..controller = c
      ..camera(
        c.cameraPosition ??
            ml.CameraPosition(
              target: ml.LatLng(
                map.initialCamera.latitude,
                map.initialCamera.longitude,
              ),
              zoom: map.initialCameraZoom,
            ),
        reachDp: _reachDp,
        animate: false,
      );
    unawaited(_setHeat(c, map.heatCapsules));
    unawaited(_stage.setCapsules(map.visibleCapsules));
    if (!mounted) return;
    setState(() => _styled = true);
    if (_shown case final shown?) {
      unawaited(_showSelected(shown, jump: false));
    }
    if (_focus.pending != null) unawaited(_showFocusedCapsule());
  }

  /// The pins, without the one drawn on its own (selected).
  static List<Object> _pinsFilter(String? hidden) => [
    'all',
    [
      '==',
      ['get', 'kind'],
      'pin',
    ],
    [
      '!=',
      ['get', 'id'],
      hidden ?? '',
    ],
  ];

  static Map<String, dynamic> _features(Iterable<Capsule> capsules) => {
    'type': 'FeatureCollection',
    'features': [
      for (final c in capsules)
        if (c.location case final at?)
          {
            'type': 'Feature',
            'id': c.id,
            'properties': {'id': c.id, 'color': c.color.name},
            'geometry': {
              'type': 'Point',
              'coordinates': [at.longitude, at.latitude],
            },
          },
    ],
  };

  /// The heat's points, written as GeoJSON in a background isolate from a
  /// flat list of coordinates: built here for 2,000 capsules it held up a
  /// frame of a pinch (20 ms) when new capsules arrived.
  static Future<void> _setHeat(
    ml.MapLibreMapController c,
    Iterable<Capsule> capsules,
  ) async {
    final at = [
      for (final capsule in capsules)
        if (capsule.location case final p?) ...[p.longitude, p.latitude],
    ];
    final json = await compute(_pointsJson, Float64List.fromList(at));
    await c.editGeoJsonSource(_heatSource, json);
  }

  static String _pointsJson(Float64List at) {
    final out = StringBuffer('{"type":"FeatureCollection","features":[');
    for (var i = 0; i + 1 < at.length; i += 2) {
      if (i > 0) out.write(',');
      out
        ..write('{"type":"Feature","properties":{},"geometry":')
        ..write('{"type":"Point","coordinates":[')
        ..write(at[i])
        ..write(',')
        ..write(at[i + 1])
        ..write(']}}');
    }
    out.write(']}');
    return out.toString();
  }

  static Map<String, dynamic> _point(GeoPosition? at) => {
    'type': 'FeatureCollection',
    'features': [
      if (at != null)
        {
          'type': 'Feature',
          'properties': <String, dynamic>{},
          'geometry': {
            'type': 'Point',
            'coordinates': [at.longitude, at.latitude],
          },
        },
    ],
  };

  /// New capsules or a new position: the sources get them (the pins and
  /// bubbles regrouped by the stage).
  void _syncData(MapController map) {
    final c = _controller;
    if (!_styled || c == null) return;
    if (_dataVersion != map.capsulesVersion) {
      _dataVersion = map.capsulesVersion;
      unawaited(_stage.setCapsules(map.visibleCapsules));
      unawaited(_setHeat(c, map.heatCapsules));
      // A selected capsule the filter now hides: its card goes.
      final selected = _selected;
      if (selected != null &&
          !map.visibleCapsules.any((c) => c.id == selected.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _select(null));
      }
    }
    if (_meAt != map.myPosition) {
      _meAt = map.myPosition;
      unawaited(_setSource(c, _meSource, _point(map.myPosition)));
    }
  }

  // ------------------------------------------------------------ selection

  void _select(Capsule? capsule) {
    if (!mounted || capsule?.id == _selected?.id) return;
    setState(() => _selected = capsule);
    if (capsule != null) {
      unawaited(_showSelected(capsule, jump: true));
    } else if (_shown != null) {
      _motion.land();
      _run();
    }
  }

  /// The selected capsule's pin leaves the pins layer for its own: hidden
  /// there by the filter, drawn here grown and lifted.
  ///
  /// The grown pin covers the plain one, so the plain one is hidden only once
  /// the new layer is drawn (a source is read in the background: hidden at
  /// once, the pin was missing for a frame).
  Future<void> _showSelected(Capsule capsule, {required bool jump}) async {
    final previous = _shown;
    _shown = capsule;
    final c = _controller;
    if (c == null || !_styled) return;
    if (previous != null && previous.id != capsule.id) {
      // Another pin was up: its plain pin is back under it first, so swapping
      // the layer's capsule never leaves its spot empty.
      await c.setFilter(_pinsLayer, _pinsFilter(null));
      await _drawn();
      if (!mounted || _shown?.id != capsule.id) return;
    }
    _motion.jumpAgain();
    if (!jump || AppMotion.reduced(context)) {
      _motion.ms = SelectedPin.swayEnd;
    }
    _ticker.stop();
    _send();
    if (capsule.location case final at?) {
      _sentSelected = (
        x: GroupNode.worldX(at.longitude),
        y: GroupNode.worldY(at.latitude),
        opacity: 1.0,
        scale: 1.0,
      );
    }
    await _setSource(c, _selectedSource, _features([capsule]));
    await _drawn();
    if (!mounted || _shown?.id != capsule.id) return;
    unawaited(c.setFilter(_pinsLayer, _pinsFilter(capsule.id)));
    _run();
  }

  /// A few frames: what was just sent to the map is drawn.
  Future<void> _drawn() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  void _run() {
    if (AppMotion.reduced(context)) {
      _motion.landMs = 0;
      if (_motion.landing) unawaited(_finishLanding());
      return;
    }
    _motion.landMs = SelectedPin.landing.inMilliseconds;
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    _motion.ms += (elapsed - _last).inMilliseconds;
    _last = elapsed;
    if (_motion.landing && _motion.landed) {
      _ticker.stop();
      unawaited(_finishLanding());
      return;
    }
    // Every frame while it jumps, sways and lands; the slow hover a step
    // every 33 ms (SelectedPin.hoverStep).
    final hovering = !_motion.landing && _motion.ms >= SelectedPin.swayEnd;
    if (hovering &&
        _motion.ms - _sentAt < SelectedPin.hoverStep.inMilliseconds) {
      return;
    }
    _send();
  }

  /// The pin's pose as the layer's paint and rotation: lifted by its
  /// translation, leaning by its rotation; the shadow stronger the higher it
  /// floats.
  void _send() {
    final c = _controller;
    if (c == null || !_styled) return;
    _sentAt = _motion.ms;
    final pose = _motion.pose;
    unawaited(
      c.setLayerProperties(
        _selectedLayer,
        _Props({
          'icon-translate': [0, -pose.lift],
          'icon-rotate': pose.degrees,
        }),
      ),
    );
    unawaited(
      c.setLayerProperties(
        _shadowLayer,
        _Props({'icon-opacity': (pose.lift / 6).clamp(0.0, 1.0)}),
      ),
    );
  }

  /// Down on its spot: back into the pins layer, and its own layer emptied
  /// once the plain pin is drawn under it.
  Future<void> _finishLanding() async {
    final landed = _shown;
    _shown = null;
    final c = _controller;
    if (c == null || !_styled || landed == null) return;
    await c.setFilter(_pinsLayer, _pinsFilter(null));
    await _drawn();
    if (_shown != null) return;
    _sentSelected = null;
    await _setSource(c, _selectedSource, _features(const []));
  }

  /// How far the screen reaches from its middle (dp): half its diagonal,
  /// so a turned map counts its corners too.
  double get _reachDp {
    final size = MediaQuery.sizeOf(context);
    return math.sqrt(size.width * size.width + size.height * size.height) / 2;
  }

  /// The shown pins and bubbles on screen, in physical pixels (for the
  /// perf test's taps).
  Future<List<(GroupNode, Offset)>> _onScreenNodes() async {
    final camera = _controller?.cameraPosition;
    final level = _stage.level;
    if (camera == null || level == null) return const [];
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    // Projected from the camera (the test never turns the map).
    final scale = CapsuleGroups.worldDp * math.pow(2, camera.zoom);
    final cx = GroupNode.worldX(camera.target.longitude);
    final cy = GroupNode.worldY(camera.target.latitude);
    return [
      for (final n in _stage.groups.at(level))
        if (Offset(
              size.width / 2 + (n.x - cx) * scale,
              size.height / 2 + (n.y - cy) * scale,
            )
            case final at
            when at.dx > 60 &&
                at.dx < size.width - 90 &&
                at.dy > 160 &&
                at.dy < size.height - 200)
          (n, at * ratio),
    ];
  }

  Future<Offset?> _pinOnScreen(int skip) async {
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final middle = Offset(size.width, size.height) * ratio / 2;
    final shown = await _onScreenNodes();
    final pins = [
      for (final (n, at) in shown)
        if (!n.isBubble) at,
    ]..sort((a, b) => (a - middle).distance.compareTo((b - middle).distance));
    debugPrint(
      'MAPHOOK level ${_stage.level} zoom ${_zoom.toStringAsFixed(2)} '
      'on screen ${shown.length} pins ${pins.length}',
    );
    if (pins.length <= skip) return null;
    // The pin's body, a little above its tip (the anchor).
    return pins[skip] - Offset(0, 20 * ratio);
  }

  Future<Offset?> _emptyOnScreen() async {
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    // The middle of each marker (a pin stands above its tip).
    final taken = [
      for (final (n, at) in await _onScreenNodes())
        n.isBubble ? at : at - Offset(0, 24 * ratio),
    ];
    for (var y = 200.0; y < size.height - 220; y += 40) {
      for (var x = 70.0; x < size.width - 100; x += 40) {
        final at = Offset(x, y) * ratio;
        if (taken.every((t) => (t - at).distance > 64 * ratio)) return at;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------- taps

  void _onFeatureTapped(
    math.Point<double> point,
    ml.LatLng at,
    String id,
    String layerId,
    ml.Annotation? annotation,
  ) {
    final map = context.read<MapController>();
    if (layerId == _pinsLayer) {
      for (final c in map.visibleCapsules) {
        if (c.id == id) {
          _select(c);
          return;
        }
      }
    } else if (layerId == _bubblesLayer) {
      final bubble = _stage.node(id);
      if (bubble != null) unawaited(_openBubble(bubble));
    }
  }

  /// In on a bubble's capsules: the camera fits them (as the Google map
  /// does); all in one spot, in to where the bubble splits.
  Future<void> _openBubble(GroupNode bubble) async {
    final at = ml.LatLng(bubble.latitude, bubble.longitude);
    final tiny =
        bubble.north - bubble.south < 1e-4 && bubble.east - bubble.west < 1e-4;
    if (tiny) {
      final level = _stage.level ?? CapsuleGroups.levelFor(_zoom);
      final splits =
          _stage.groups.splitsAt(bubble, level) ?? CapsuleGroups.maxLevel + 1;
      return _animate(
        ml.CameraUpdate.newLatLngZoom(at, math.max(splits.toDouble(), _zoom)),
        'bubble_split',
      );
    }
    final update = ml.CameraUpdate.newLatLngBounds(
      ml.LatLngBounds(
        southwest: ml.LatLng(bubble.south, bubble.west),
        northeast: ml.LatLng(bubble.north, bubble.east),
      ),
      left: 64,
      top: 96,
      right: 64,
      bottom: NavbarWidget.coveredHeight(context) + 64,
    );
    await _animate(update, 'bubble', duration: AppMotion.reveal);
  }

  /// Every camera move the app makes (the buttons, a bubble, a capsule, the
  /// user's place) goes through here: eased by the map itself over
  /// [duration] (about a third of a second, like its own double tap; a touch
  /// stops it where it is), at once with reduced motion. Traced with
  /// MAP_TRACE ([MapStats.cameraMove]).
  Future<void> _animate(
    ml.CameraUpdate update,
    String source, {
    Duration duration = AppMotion.slow,
  }) async {
    final c = await _ready.future;
    if (!mounted) return;
    final reduced = AppMotion.reduced(context);
    MapStats.instance.cameraMove(source, reduced ? Duration.zero : duration);
    if (reduced) {
      await c.moveCamera(update);
    } else {
      await c.animateCamera(update, duration: duration);
    }
  }

  // --------------------------------------------------------------- camera

  void _onFocusRequested() {
    if (_focus.pending == null) return;
    unawaited(_showFocusedCapsule());
  }

  /// Moves to a capsule requested from the history list or a notification.
  Future<void> _showFocusedCapsule() async {
    await _ready.future;
    if (!_styled || !mounted) return;
    final capsule = _focus.take();
    final location = capsule?.location;
    if (capsule == null || location == null) return;
    _select(null);
    await _animate(
      ml.CameraUpdate.newLatLngZoom(
        ml.LatLng(location.latitude, location.longitude),
        17,
      ),
      'focus',
      duration: AppMotion.reveal,
    );
    _select(capsule);
  }

  /// A map button: a tick under the finger, then the move.
  Future<void> _button(ml.CameraUpdate update, String source) {
    unawaited(HapticFeedback.selectionClick());
    return _animate(update, source);
  }

  Future<void> _goToMe(MapController map) async {
    unawaited(HapticFeedback.selectionClick());
    final position = await map.locateMe();
    if (!mounted) return;
    if (position == null) {
      final l10n = context.l10n;
      final availability = map.availability;
      PopupNotificationService.showError(
        context: context,
        message: switch (availability) {
          LocationAvailability.serviceDisabled => l10n.mapLocationServiceOff,
          LocationAvailability.denied ||
          LocationAvailability.deniedForever => l10n.mapLocationDenied,
          LocationAvailability.available => l10n.mapLocationUnknown,
        },
        position: NotificationPosition.top,
      );
      // Only the system settings can turn these back on.
      if (availability == LocationAvailability.deniedForever) {
        unawaited(Geolocator.openAppSettings());
      } else if (availability == LocationAvailability.serviceDisabled) {
        unawaited(context.read<LocationService>().openSettings());
      }
      return;
    }
    await _animate(
      ml.CameraUpdate.newLatLngZoom(
        ml.LatLng(position.latitude, position.longitude),
        _zoom < 14 ? 15 : _zoom,
      ),
      'me',
      duration: AppMotion.reveal,
    );
  }

  void _reportLocationProblem(MapController map) {
    if (_reportedLocationProblem || !map.usedFallbackCamera) return;
    _reportedLocationProblem = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = context.l10n;
      PopupNotificationService.showError(
        context: context,
        message: switch (map.availability) {
          LocationAvailability.serviceDisabled => l10n.mapLocationServiceOff,
          LocationAvailability.denied ||
          LocationAvailability.deniedForever => l10n.mapLocationDenied,
          LocationAvailability.available => l10n.mapLocationUnknown,
        },
        position: NotificationPosition.top,
      );
    });
  }

  /// The map stopped: what is on screen goes to the controller (it loads
  /// the public capsules around it).
  Future<void> _onIdle(MapController map) async {
    MapStats.instance.cameraIdle();
    _moving = false;
    _active();
    if (_pointers == 0) MapStats.instance.gestureEnded();
    final c = _controller;
    if (c == null) return;
    if (c.cameraPosition case final camera?) {
      _saveCamera(camera);
      // A jump (moveCamera) may report no move: the zoom and the shown
      // level catch up here, at once.
      _zoom = camera.zoom;
      _stage.camera(camera, reachDp: _reachDp, animate: false);
    }
    try {
      final bounds = await c.getVisibleRegion();
      map.onCameraIdle(
        GeoPosition(
          (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
          (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
        ),
        _zoom,
        view: GeoBounds(
          south: bounds.southwest.latitude,
          west: bounds.southwest.longitude,
          north: bounds.northeast.latitude,
          east: bounds.northeast.longitude,
        ),
      );
    } on Object {
      // The map went away while this ran.
    }
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapController>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    // The map's own ground colour, not a white page, until it has drawn
    // (M-06).
    final ground = dark ? AppColors.mapGroundDark : AppColors.mapGroundLight;
    final saved = _savedCamera;
    // A saved camera: the map opens there at once, the capsules come when
    // they are loaded; otherwise it waits for the start position.
    if (!_cameraRead ||
        (saved == null &&
            (map.state == MapLoadState.loading || map.icons == null))) {
      return ColoredBox(color: ground);
    }
    _reportLocationProblem(map);
    // A theme switch loads the other style; its layers are added again.
    if (_styleDark != null && _styleDark != dark) _styled = false;
    _styleDark = dark;
    _syncData(map);

    final start = map.initialCamera;
    final selected = _selected;
    final bottom = NavbarWidget.coveredHeight(context) + 12;
    final cardHeight = CapsuleInfoPanel.heightFor(context);
    final motion = AppMotion.of(context, AppMotion.emphasized);
    final noCapsules = context.select<OwnCapsulesStore, bool>(
      (s) => s.isLoaded && s.capsules.isEmpty,
    );
    final showHint = selected == null && noCapsules && !_hintClosed;
    final raised = selected != null
        ? cardHeight + 12
        : showHint
        ? FirstCapsuleHint.heightFor(context) + 12
        : 0.0;
    return PopScope(
      // Back closes the card first.
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(null);
      },
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: ground)),
          Listener(
            onPointerDown: (e) {
              MapStats.instance
                ..touch('down')
                ..finger(e.pointer, e.localPosition);
              if (_pointers++ == 0) MapStats.instance.gestureStarted();
              _active();
            },
            onPointerMove: (e) =>
                MapStats.instance.finger(e.pointer, e.localPosition),
            onPointerUp: (e) {
              MapStats.instance
                ..touch('up')
                ..finger(e.pointer, null);
              _pointers = math.max(0, _pointers - 1);
              _active();
            },
            onPointerCancel: (e) {
              MapStats.instance.finger(e.pointer, null);
              _pointers = math.max(0, _pointers - 1);
              _active();
            },
            child: ml.MapLibreMap(
              // The app's map palette over OpenFreeMap tiles; the tile
              // source is the owner's decision (DECISION.md).
              styleString: dark ? AppMapStyles.dark : AppMapStyles.light,
              foregroundLoadColor: ground,
              initialCameraPosition: _debugZoom != null || saved == null
                  ? ml.CameraPosition(
                      target: ml.LatLng(start.latitude, start.longitude),
                      zoom: _debugZoom ?? map.initialCameraZoom,
                    )
                  : saved,
              trackCameraPosition: true,
              // Never out to the whole world, never past street level
              // (MapLimits, mission 2).
              minMaxZoomPreference: const ml.MinMaxZoomPreference(
                MapLimits.minZoom,
                MapLimits.maxZoom,
              ),
              compassEnabled: false,
              tiltGesturesEnabled: false,
              annotationOrder: const [],
              // OpenStreetMap's credit stays visible above the navigation
              // bar and the card, like the Google logo (F-12, F-14).
              attributionButtonPosition:
                  ml.AttributionButtonPosition.bottomLeft,
              attributionButtonMargins: math.Point(12, bottom + raised),
              onMapCreated: (c) {
                _controller = c;
                if (!_ready.isCompleted) _ready.complete(c);
                c.onFeatureTapped.add(_onFeatureTapped);
                if (MapStats.enabled) {
                  MapStats.instance
                    ..moveCamera = (target, zoom) async {
                      await c.moveCamera(
                        ml.CameraUpdate.newLatLngZoom(
                          ml.LatLng(target.latitude, target.longitude),
                          zoom,
                        ),
                      );
                    }
                    ..pinOnScreen = _pinOnScreen
                    ..emptyOnScreen = _emptyOnScreen;
                }
              },
              onStyleLoadedCallback: () => unawaited(_onStyleLoaded()),
              onMapClick: (_, _) => _select(null),
              onCameraMove: (position) {
                MapStats.instance
                  ..cameraMoved()
                  ..cameraAt(position.zoom);
                _zoom = position.zoom;
                _bearing.value = position.bearing;
                MapStats.instance.pinchCamera(
                  position.zoom,
                  position.target.latitude,
                  position.target.longitude,
                  position.bearing,
                  MediaQuery.sizeOf(context),
                );
                _stage.camera(
                  position,
                  reachDp: _reachDp,
                  // Unseen below the markers' band, and at once with
                  // reduced motion.
                  animate:
                      !AppMotion.reduced(context) &&
                      position.zoom > MapZoomVisuals.markersFrom,
                );
                if (!_moving) {
                  _moving = true;
                  _active();
                }
                // Zoomed out to the heat: no pins, their card goes too.
                if (position.zoom < MapZoomVisuals.markersFrom) _select(null);
              },
              onCameraIdle: () => unawaited(_onIdle(map)),
            ),
          ),
          if (MapStats.harness)
            const Positioned(top: 0, left: 0, child: MapHarnessStrip()),
          // What the map shows (B5), top left under the status bar.
          Positioned(
            top: MediaQuery.viewPaddingOf(context).top + 12,
            left: 16,
            child: _FilterButton(
              active: map.filter.activeCount,
              onTap: () => MapFilterSheet.show(
                context,
                filter: map.filter,
                onChanged: map.setFilter,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.viewPaddingOf(context).top + 12,
            right: 16,
            child: const StreakPill(),
          ),
          AnimatedPositioned(
            duration: motion,
            curve: AppMotion.emphasizedCurve,
            right: 16,
            bottom: bottom + raised,
            child: _MyLocationButton(onTap: () => _goToMe(map)),
          ),
          AnimatedPositioned(
            duration: motion,
            curve: AppMotion.emphasizedCurve,
            right: 16,
            bottom:
                bottom + raised + AppSizes.mapControl + AppSizes.mapControlGap,
            child: _ZoomButtons(
              onZoomIn: () =>
                  unawaited(_button(ml.CameraUpdate.zoomIn(), 'zoom_in')),
              onZoomOut: () =>
                  unawaited(_button(ml.CameraUpdate.zoomOut(), 'zoom_out')),
            ),
          ),
          AnimatedPositioned(
            duration: motion,
            curve: AppMotion.emphasizedCurve,
            right: 16,
            bottom:
                bottom +
                raised +
                AppSizes.mapControl * 3 +
                1 +
                AppSizes.mapControlGap * 2,
            child: MapCompass(
              size: AppSizes.mapControl,
              bearing: _bearing,
              onTap: () =>
                  unawaited(_button(ml.CameraUpdate.bearingTo(0), 'compass')),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottom,
            child: AnimatedSwitcher(
              duration: motion,
              switchInCurve: AppMotion.emphasizedCurve,
              switchOutCurve: AppMotion.exit,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: selected == null
                  ? showHint
                        ? Center(
                            key: const ValueKey('hint'),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: FirstCapsuleHint(
                                onTap: () => AppRoutes.toCamera(context),
                                onClose: _closeHint,
                              ),
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('none'),
                            width: double.infinity,
                          )
                  : GestureDetector(
                      key: ValueKey(selected.id),
                      // Swipe down to close.
                      onVerticalDragEnd: (details) {
                        if ((details.primaryVelocity ?? 0) > 150) _select(null);
                      },
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: SizedBox(
                            height: cardHeight,
                            child: CapsuleInfoPanel(
                              capsule: selected,
                              onMoreInfo: () => CapsuleDetailDialog.show(
                                context,
                                selected,
                                // Back to the capsule's place on the map.
                                onPlaceTap: () => _focus.focus(selected),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
