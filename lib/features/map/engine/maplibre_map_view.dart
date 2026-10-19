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
const _heatLayer = 'heat';
const _pinsLayer = 'pins';
const _bubblesLayer = 'bubbles';
const _meLayer = 'me';
const _shadowLayer = 'selected_shadow';

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

  /// What was last saved as the camera (MapController opens there, M-06).
  String? _cameraSaved;

  /// The marker pictures, drawn while the map view starts (ready by the
  /// time its style is), for the theme they were drawn for.
  Future<Map<String, Uint8List>>? _images;
  bool? _imagesDark;

  // Fingers and camera, for MapStats.
  int _pointers = 0;
  bool _moving = false;

  /// The capsule whose card is open, and its pin's motion (M-02): it jumps,
  /// sways and hovers, the same marker as at rest, grown and lifted by the
  /// pins layer ([_pinPose]); [_shown] is the pin posed (until it has
  /// landed).
  Capsule? _selected;
  Capsule? _shown;
  var _motion = PinMotion();

  /// A pin landing while another rises (another capsule was picked).
  (Capsule, PinMotion)? _landingPin;

  /// The posed pins' ids as last sent (the shadow's filter).
  var _posedIds = <String>{};
  late final Ticker _ticker = createTicker(_tick);
  late final _stage = _GroupStage(vsync: this)
    ..onSent = _onPictureSent
    ..onLife = _onLife;

  /// The layers' clock while pieces grow in or shrink away (_GroupStage
  /// life): the pins' and bubbles' sizes, sent every frame until done.
  late final Ticker _lifeTicker = createTicker((_) => _tickLife());
  int _lifeT = 0;

  void _onLife() {
    if (!_lifeTicker.isActive) unawaited(_lifeTicker.start());
  }

  void _tickLife() {
    _sendLife();
    if (_stage.living) return;
    _lifeTicker.stop();
    _stage.lifeDone();
  }

  void _sendLife() {
    final c = _controller;
    if (c == null || !_styled) return;
    _lifeT = _stage.now;
    unawaited(
      c.setLayerProperties(
        _pinsLayer,
        _Props({'icon-size': _pinPose(_poses(), _lifeT)['icon-size']!}),
      ),
    );
    unawaited(
      c.setLayerProperties(
        _bubblesLayer,
        _Props({'icon-size': _bubbleSize(_lifeT)}),
      ),
    );
  }

  /// A piece's size for its life at the clock's [t]: growing in from its
  /// 'a', shrinking away from its 'g', else 1 (the same ease out and in as
  /// AppMotion.enter and exit).
  static List<Object> _lifeScale(int t) => [
    '*',
    [
      'interpolate',
      ['cubic-bezier', 0, 0, 0.58, 1],
      [
        '-',
        t,
        [
          'coalesce',
          ['get', 'a'],
          -1e9,
        ],
      ],
      0,
      0,
      _GroupStage.growMs,
      1,
    ],
    [
      'interpolate',
      ['cubic-bezier', 0.42, 0, 1, 1],
      [
        '-',
        t,
        [
          'coalesce',
          ['get', 'g'],
          1e15,
        ],
      ],
      0,
      1,
      _GroupStage.shrinkMs,
      0,
    ],
  ];

  /// The bubbles' size: bigger for more capsules, a moving piece's own,
  /// and its life.
  static List<Object> _bubbleSize(int t) => [
    '*',
    [
      'interpolate',
      ['linear'],
      ['get', 'c'],
      2,
      0.9,
      10,
      1.0,
      50,
      1.12,
      200,
      1.25,
    ],
    _pieceScale,
    _lifeScale(t),
  ];
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
  }

  Future<Map<String, Uint8List>> _markerImages(double ratio, bool dark) {
    if (_imagesDark != dark) {
      _imagesDark = dark;
      _images = MapLibreImages.cached(ratio: ratio, dark: dark);
    }
    return _images!;
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
    _revealCap?.cancel();
    _cover.dispose();
    _lifeTicker.dispose();
    _pinsWait?.cancel();
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
  List<String> get _markerLayers => const [_pinsLayer, _bubblesLayer];

  // ----------------------------------------------------------- cold start

  /// The capsule data that first held every pin of this start
  /// (MapController.complete: the pin store's, or every source's answer):
  /// once a picture of it has been drawn, the map is full (StartupReport).
  /// And the first that held every source's own answer (fresh).
  int? _fullVersion;
  int? _freshVersion;
  bool _freshMarked = false;

  /// 0: nothing marked yet; 1: the first pins; 2: full.
  int _startStage = 0;
  bool _shellMarked = false;
  bool _fullDrawn = false;

  /// The map's ground over the map until it has drawn its streets (M-06):
  /// thinned out once, so a half-drawn map (blank tiles, streets coming in
  /// piece by piece) is never seen. Painted, not an opacity layer
  /// (MOTION_CATALOG.md rule 1).
  late final AnimationController _cover =
      AnimationController(vsync: this, value: 1, duration: AppMotion.slow)
        ..addStatusListener((status) {
          if (status == AnimationStatus.dismissed && mounted) setState(() {});
        });
  bool _revealing = false;

  /// The cover goes at the latest this long after the map's buttons showed
  /// (no tiles: offline with nothing cached, a slow network).
  static const _revealAtLatest = Duration(milliseconds: 1800);
  Timer? _revealCap;

  void _reveal() {
    if (_revealing || !mounted) return;
    _revealing = true;
    _revealCap?.cancel();
    StartupReport.mark('reveal');
    if (AppMotion.reduced(context)) {
      _cover.value = 0;
    } else {
      unawaited(_cover.animateTo(0, curve: AppMotion.enter));
    }
    _revealPins();
    _maybeFull();
  }

  /// The pins and bubbles appear in one go once the map is uncovered and
  /// every pin of this start has been grouped (the pin store's, or every
  /// source's answer); on a first start at most [_pinsAtLatest] after the
  /// first source answered, later ones growing in as they come.
  void _revealPins() {
    if (!_stage.hidden || !_revealing || !mounted) return;
    final grouped = _stage.groupedVersion;
    final full = _fullVersion;
    final ready =
        grouped != null && (full == null ? _pinsWaited : grouped >= full);
    if (!ready) return;
    _pinsWait?.cancel();
    StartupReport.mark('pins_reveal');
    _stage.reveal(instant: AppMotion.reduced(context));
    if (_controller case final c?) {
      unawaited(_setHeat(c, context.read<MapController>().heatCapsules));
    }
  }

  static const _pinsAtLatest = Duration(seconds: 1);
  Timer? _pinsWait;
  bool _pinsWaited = false;

  /// Full: every pin of this start drawn, and no longer covered.
  void _maybeFull() {
    if (_fullDrawn && _revealing) StartupReport.fullyDrawn();
  }

  /// Start-up marks waiting for the map's next idle (it has drawn them).
  final _afterIdle = <VoidCallback>[];

  void _onPictureSent(int features, int? version) {
    _revealPins();
    final fresh = _freshVersion;
    if (!_freshMarked && fresh != null && version != null && version >= fresh) {
      _freshMarked = true;
      _afterIdle.add(() => StartupReport.mark('fresh'));
    }
    if (_startStage < 1 && features > 0) {
      _startStage = 1;
      _afterIdle.add(() => StartupReport.mark('pins_first'));
    }
    final full = _fullVersion;
    if (_startStage < 2 && full != null && version != null && version >= full) {
      _startStage = 2;
      _afterIdle.add(() {
        _fullDrawn = true;
        _maybeFull();
      });
    }
  }

  void _onMapIdle() {
    StartupReport.mark('streets');
    final pending = List.of(_afterIdle);
    _afterIdle.clear();
    for (final mark in pending) {
      mark();
    }
    // The streets are drawn, our layers on them.
    if (_styled) _reveal();
  }

  // ---------------------------------------------------------------- style

  Future<void> _onStyleLoaded() async {
    final c = _controller;
    if (c == null || !mounted) return;
    StartupReport.mark('style_native');
    final map = context.read<MapController>();
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final images = await _markerImages(ratio, dark);
    StartupReport.mark('images_made');
    // All at once, not one after another each waiting for its answer.
    await Future.wait([
      for (final MapEntry(:key, :value) in images.entries)
        c.addImage(key, value),
    ]);
    StartupReport.mark('images_added');
    // The data as read here: capsules that arrive while the layers are being
    // added are sent by [_syncData] once the style is ready.
    final version = map.capsulesVersion;
    final me = map.myPosition;
    // Sent in this order (the channel keeps it) and waited for together:
    // each waited for alone, they took 0.2 to 0.3 s of a cold start.
    final added = <Future<void>>[
      // Empty first, filled as a string (_setSource): off the main thread.
      c.addGeoJsonSource(_heatSource, _features(const [])),
      // Pins and bubbles, at rest and moving: one source ([_GroupStage]).
      c.addGeoJsonSource(_capsulesSource, _features(const [])),
      c.addGeoJsonSource(_meSource, _point(me)),
    ];
    added.add(
      c.addHeatmapLayer(
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
      ),
    );
    // The soft oval under a floating pin, on the ground under the pins; its
    // filter and strength follow the pin's pose (_sendPose).
    added.add(
      c.addSymbolLayer(
        _capsulesSource,
        _shadowLayer,
        const ml.SymbolLayerProperties(
          iconImage: 'shadow',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconOpacity: 0,
        ),
        filter: _posedFilter(const {}),
        enableInteraction: false,
      ),
    );
    // The zoom's opacity (no piece is ever see-through on its own:
    // GroupMotion).
    final opacity = MapZoomVisuals.markerOpacityExpression();
    final pose = _pinPose(_poses(), _lifeT);
    added.add(
      c.addSymbolLayer(
        _capsulesSource,
        _pinsLayer,
        ml.SymbolLayerProperties(
          iconImage: const ['get', 'm'],
          iconAnchor: 'bottom',
          iconSize: pose['icon-size'],
          iconOffset: pose['icon-offset'],
          iconRotate: pose['icon-rotate'],
          symbolSortKey: pose['symbol-sort-key'],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconOpacity: opacity,
        ),
        filter: const [
          '==',
          ['get', 'k'],
          0,
        ],
      ),
    );
    added.add(
      c.addSymbolLayer(
        _capsulesSource,
        _bubblesLayer,
        ml.SymbolLayerProperties(
          iconImage: const ['get', 'm'],
          // Bigger for more capsules: a clear scale by count.
          iconSize: _bubbleSize(_lifeT),
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconOpacity: opacity,
          // The bigger bubbles on top.
          symbolSortKey: const ['get', 'c'],
        ),
        filter: const [
          '==',
          ['get', 'k'],
          1,
        ],
      ),
    );
    added.add(
      c.addSymbolLayer(
        _meSource,
        _meLayer,
        const ml.SymbolLayerProperties(
          iconImage: 'me',
          iconAnchor: 'bottom',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
        enableInteraction: false,
      ),
    );
    await Future.wait(added);
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
    // The heat comes with the pins (_revealPins), never in steps.
    if (!_stage.hidden) unawaited(_setHeat(c, map.heatCapsules));
    unawaited(_stage.setCapsules(map.visibleCapsules, version: version));
    if (!mounted) return;
    StartupReport.mark('style');
    setState(() => _styled = true);
    if (_shown case final shown?) _showSelected(shown, jump: false);
    if (_focus.pending != null) unawaited(_showFocusedCapsule());
  }

  /// A piece's own size (moving, GroupMotion); 1 when not sent.
  static const _pieceScale = [
    'coalesce',
    ['get', 's'],
    1,
  ];

  /// The pins layer's size, lift and lean: each posed pin ([poses], by its
  /// capsule's id) grown, floating and leaning, on top of the others; every
  /// other pin as it is. One layer, one update: the selected pin is the
  /// same marker as when it rests, so it is never drawn twice or missing
  /// (docs/map/FLASH_FIX.md).
  static Map<String, Object> _pinPose(
    Map<String, SelectedPinPose> poses,
    int lifeT,
  ) {
    Object pick(Object Function(SelectedPinPose) of, Object rest) =>
        poses.isEmpty
        ? rest
        : [
            'case',
            for (final MapEntry(:key, value: pose) in poses.entries) ...[
              [
                '==',
                ['get', 'id'],
                key,
              ],
              of(pose),
            ],
            rest,
          ];
    return {
      'icon-size': [
        '*',
        _pieceScale,
        pick((p) => p.scale, 1),
        _lifeScale(lifeT),
      ],
      // In the icon's own units: its size multiplies the offset.
      'icon-offset': pick(
        (p) => [
          'literal',
          [0, -p.lift / p.scale],
        ],
        [
          'literal',
          [0, 0],
        ],
      ),
      'icon-rotate': pick((p) => p.degrees, 0),
      'symbol-sort-key': pick((_) => 1, 0),
    };
  }

  /// The posed pins' ids, as a filter (the shadow's).
  static List<Object> _posedFilter(Iterable<String> ids) => [
    'in',
    ['get', 'id'],
    [
      'literal',
      [...ids, ''],
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
    if (_fullVersion == null && map.complete) {
      _fullVersion = map.capsulesVersion;
    }
    if (_pinsWait == null && map.visibleCapsules.isNotEmpty) {
      _pinsWait = Timer(_pinsAtLatest, () {
        _pinsWaited = true;
        _revealPins();
      });
    }
    if (_freshVersion == null && map.allAnswered) {
      _freshVersion = map.capsulesVersion;
    }
    final c = _controller;
    if (!_styled || c == null) return;
    if (_dataVersion != map.capsulesVersion) {
      _dataVersion = map.capsulesVersion;
      unawaited(
        _stage.setCapsules(
          map.visibleCapsules,
          version: map.capsulesVersion,
          animate: !AppMotion.reduced(context),
        ),
      );
      if (!_stage.hidden) unawaited(_setHeat(c, map.heatCapsules));
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
      _showSelected(capsule, jump: true);
    } else if (_shown != null) {
      _motion.land();
      _run();
    }
  }

  /// The selected capsule's pin rises where it stands: the same marker,
  /// grown and floating ([_pinPose]). Another pin still up lands meanwhile;
  /// the same pin caught landing rises again from where it is.
  void _showSelected(Capsule capsule, {required bool jump}) {
    final previous = _shown;
    _shown = capsule;
    final caught = previous?.id == capsule.id && _motion.landing;
    if (previous != null && previous.id != capsule.id) {
      _landingPin = (previous, _motion..land());
      _motion = PinMotion();
    }
    _motion.jumpAgain(fromHere: caught);
    if (!jump || AppMotion.reduced(context)) {
      _motion.ms = SelectedPin.swayEnd;
    }
    _sendPose();
    _run();
  }

  void _run() {
    if (AppMotion.reduced(context)) {
      // No motion: landed at once, the hover held still.
      _landingPin = null;
      if (_motion.landing) {
        _shown = null;
      }
      _sendPose();
      return;
    }
    _motion.landMs = SelectedPin.landing.inMilliseconds;
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final step = (elapsed - _last).inMilliseconds;
    _last = elapsed;
    _motion.ms += step;
    if (_landingPin case (_, final other)?) {
      other.ms += step;
      // Down: at rest in the next pose sent.
      if (other.landed) _landingPin = null;
    }
    if (_motion.landing && _motion.landed) {
      // Down on its spot: the same marker at rest, in one update.
      _ticker.stop();
      _shown = null;
      _sendPose();
      return;
    }
    // Every frame while a pin jumps, sways or lands; the slow hover a step
    // every 33 ms (SelectedPin.hoverStep).
    final hovering =
        _landingPin == null &&
        !_motion.landing &&
        _motion.ms >= SelectedPin.swayEnd;
    if (hovering &&
        _motion.ms - _sentAt < SelectedPin.hoverStep.inMilliseconds) {
      return;
    }
    _sendPose();
  }

  /// The posed pins: the one landing, then the selected one.
  Map<String, SelectedPinPose> _poses() => {
    if (_landingPin case (final c, final m)?) c.id: m.pose,
    if (_shown case final c?) c.id: _motion.pose,
  };

  /// The pins' pose in one update of the pins layer, and the shadows under
  /// the floating ones, stronger the higher they float.
  void _sendPose() {
    final c = _controller;
    if (c == null || !_styled) return;
    _sentAt = _motion.ms;
    final poses = _poses();
    final ids = poses.keys.toSet();
    if (ids.length != _posedIds.length || !ids.containsAll(_posedIds)) {
      _posedIds = ids;
      _stage.posed = [if (_landingPin case (final c, _)?) c, ?_shown];
      unawaited(c.setFilter(_shadowLayer, _posedFilter(ids)));
    }
    unawaited(
      c.setLayerProperties(_pinsLayer, _Props(_pinPose(poses, _lifeT))),
    );
    unawaited(
      c.setLayerProperties(
        _shadowLayer,
        _Props({
          'icon-opacity': poses.isEmpty
              ? 0
              : [
                  'case',
                  for (final MapEntry(:key, value: pose) in poses.entries) ...[
                    [
                      '==',
                      ['get', 'id'],
                      key,
                    ],
                    (pose.lift / 6).clamp(0.0, 1.0),
                  ],
                  0,
                ],
        }),
      ),
    );
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
          _centerOn(c);
          if (map.isStoredOnly(id)) {
            unawaited(_openStored(map, id));
          } else {
            _select(c);
          }
          return;
        }
      }
    } else if (layerId == _bubblesLayer) {
      final bubble = _stage.node(id);
      if (bubble != null) unawaited(_openBubble(bubble));
    }
  }

  /// A pin shown from the pin store before its source answered: what it
  /// holds is never shown; the capsule is read from the server (which checks
  /// that this user may still see it), or a message says it is gone.
  Future<void> _openStored(MapController map, String id) async {
    // At once from the phone's copy of Firestore when it has it; the
    // server's answer then keeps it open or closes it.
    final cached = await map.cachedCapsule(id);
    if (!mounted) return;
    if (cached != null) _select(cached);
    final capsule = await map.freshCapsule(id);
    if (!mounted) return;
    if (capsule != null) {
      if (_selected == null) _select(capsule);
      return;
    }
    if (_selected?.id == id) _select(null);
    PopupNotificationService.showError(
      context: context,
      message: context.l10n.mapCapsuleUnavailable,
      position: NotificationPosition.top,
    );
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

  /// A capsule tapped: the map moves to put it in the middle, keeping its
  /// zoom (as the Google map did on its own).
  void _centerOn(Capsule capsule) {
    final at = capsule.location;
    if (at == null) return;
    unawaited(
      _animate(
        ml.CameraUpdate.newLatLng(ml.LatLng(at.latitude, at.longitude)),
        'select',
      ),
    );
  }

  /// The credit's (i): its 44 dp target placed so the disc stands 8 dp to
  /// the right of the filter button.
  static const double _creditLeft =
      16 +
      AppSizes.mapControl +
      8 -
      (AppSizes.mapControl - MapCreditsButton.disc) / 2;

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
    // Drawn while the map starts.
    unawaited(_markerImages(MediaQuery.devicePixelRatioOf(context), dark));
    // Until it knows where to open: at once where it last stopped (M-06),
    // the capsules coming when they are loaded.
    if (map.state == MapLoadState.loading) return ColoredBox(color: ground);
    _reportLocationProblem(map);
    // A theme switch loads the other style; its layers are added again.
    if (_styleDark != null && _styleDark != dark) _styled = false;
    _styleDark = dark;
    _syncData(map);

    if (!_shellMarked) {
      _shellMarked = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => StartupReport.mark('shell'),
      );
      _revealCap = Timer(_revealAtLatest, _reveal);
    }
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
              _reveal();
              MapCreditsControl.mapTouched();
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
              initialCameraPosition: ml.CameraPosition(
                target: ml.LatLng(start.latitude, start.longitude),
                zoom: _debugZoom ?? map.initialCameraZoom,
              ),
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
              // MapLibre's own (i) button cannot be switched off through
              // the plugin: it is moved off the map; the app's own credit
              // replaces it (MapCreditsControl, docs/map/ATTRIBUTION.md).
              attributionButtonPosition:
                  ml.AttributionButtonPosition.bottomLeft,
              attributionButtonMargins: const math.Point(-400, -400),
              onMapCreated: (c) {
                StartupReport.mark('map_created');
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
              onMapIdle: _onMapIdle,
            ),
          ),
          if (!_revealing || _cover.value > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: TintPainter(_cover, ground)),
              ),
            ),
          if (MapStats.harness)
            const Positioned(top: 0, left: 0, child: MapHarnessStrip()),
          // The map's data credit, top left right next to the filter button
          // (its disc 8 dp from it; the line short of the streak pill).
          Positioned(
            top: MediaQuery.viewPaddingOf(context).top + 12,
            left: _creditLeft,
            child: MapCreditsControl(
              maxWidth:
                  MediaQuery.sizeOf(context).width - _creditLeft - 16 - 100,
              mapShown: _styled,
            ),
          ),
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
