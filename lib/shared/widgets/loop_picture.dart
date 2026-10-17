import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../core/theme/app_motion.dart';
import '../../data/services/app_image_cache.dart';

/// The frames of a loop capsule played one after another, over and over.
/// [sources] are download URLs, `file:` URIs or file paths (a capsule
/// still on the phone, the creation preview). Starts once every frame is
/// loaded (no flicker); with reduced motion, or while the widget is not
/// shown (TickerMode off), it rests on the first frame.
class LoopPicture extends StatefulWidget {
  const LoopPicture({
    super.key,
    required this.sources,
    this.frameDelay = const Duration(milliseconds: 300),
    this.fit = BoxFit.cover,
    this.decodeWidth,
  });

  final List<String> sources;
  final Duration frameDelay;
  final BoxFit fit;

  /// Decode width in logical pixels for network frames (default: the
  /// space the widget gets is not known up front, so a card's width).
  final double? decodeWidth;

  @override
  State<LoopPicture> createState() => _LoopPictureState();
}

class _LoopPictureState extends State<LoopPicture> {
  int _index = 0;
  Timer? _timer;
  bool _ready = false;
  List<ImageProvider> _providers = const [];

  ImageProvider _provider(String source, int? width) {
    if (source.startsWith('http')) {
      return AppImageCache.provider(source, width: width);
    }
    final file = source.startsWith('file:')
        ? File.fromUri(Uri.parse(source))
        : File(source);
    return ResizeImage.resizeIfNeeded(width, null, FileImage(file));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = AppImageCache.decodeWidth(
      widget.decodeWidth ?? 360,
      MediaQuery.devicePixelRatioOf(context),
    );
    final providers = [for (final s in widget.sources) _provider(s, width)];
    if (providers.length != _providers.length ||
        !_ready && _providers.isEmpty) {
      _providers = providers;
      unawaited(_preload());
    }
    _schedule();
  }

  @override
  void didUpdateWidget(LoopPicture old) {
    super.didUpdateWidget(old);
    if (old.sources.join() != widget.sources.join()) {
      _ready = false;
      _index = 0;
      _providers = const [];
      didChangeDependencies();
    } else if (old.frameDelay != widget.frameDelay) {
      _schedule();
    }
  }

  Future<void> _preload() async {
    final providers = _providers;
    try {
      await Future.wait([for (final p in providers) precacheImage(p, context)]);
    } catch (_) {
      // A frame that cannot load: the loop still plays the others' slots.
    }
    if (!mounted || providers != _providers) return;
    setState(() => _ready = true);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    final moving =
        _ready &&
        _providers.length > 1 &&
        !AppMotion.reduced(context) &&
        TickerMode.of(context);
    if (!moving) return;
    _timer = Timer.periodic(widget.frameDelay, (_) {
      if (mounted) setState(() => _index = (_index + 1) % _providers.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_providers.isEmpty) return const SizedBox.expand();
    return Image(
      image: _providers[_index.clamp(0, _providers.length - 1)],
      fit: widget.fit,
      gaplessPlayback: true,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
