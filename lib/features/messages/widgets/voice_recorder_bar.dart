import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat.dart';
import '../../../data/services/voice_service.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../chat_time.dart';

/// In place of the message field while a voice message is recorded: a
/// pulsing dot, the time, the live loudness and the buttons to throw it
/// away or send it. Recording starts when it appears and stops at
/// [ChatMessage.maxVoice] (then it is sent).
class VoiceRecorderBar extends StatefulWidget {
  const VoiceRecorderBar({
    super.key,
    required this.voice,
    required this.onSend,
    required this.onDone,
  });

  final VoiceService voice;

  /// A recording to send: its file, length and loudness bars.
  final void Function(String path, int durationMs, List<int> waveform) onSend;

  /// The bar can go (sent, thrown away or failed).
  final VoidCallback onDone;

  /// [levels] (0-32767, one per poll) as [ChatMessage.waveformBars] bars of
  /// 0-100: the loudest in each slice, relative to the loudest overall.
  static List<int> waveform(List<int> levels) {
    const count = ChatMessage.waveformBars;
    if (levels.isEmpty) return List.filled(count, 0);
    final top = levels.reduce(math.max);
    if (top <= 0) return List.filled(count, 0);
    return [
      for (var i = 0; i < count; i++)
        () {
          final from = (i * levels.length / count).floor();
          final to = math.max(
            from + 1,
            ((i + 1) * levels.length / count).floor(),
          );
          final peak = levels
              .sublist(from, math.min(to, levels.length))
              .reduce(math.max);
          // A square root lifts quiet speech so the bars are readable.
          return (math.sqrt(peak / top) * 100).round().clamp(0, 100);
        }(),
    ];
  }

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<VoiceRecorderBar>
    with SingleTickerProviderStateMixin {
  final _levels = <int>[];
  final _clock = Stopwatch();
  late final AnimationController _pulse;
  Timer? _poll;
  String? _path;
  bool _recording = false;
  bool _finishing = false;

  /// Shortest recording worth sending.
  static const _shortest = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: AppMotion.slow * 3);
    unawaited(_start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  Future<void> _start() async {
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await widget.voice.start(path);
      if (!mounted) {
        await widget.voice.cancel();
        return;
      }
      unawaited(HapticFeedback.mediumImpact());
      _path = path;
      _recording = true;
      _clock.start();
      _poll = Timer.periodic(const Duration(milliseconds: 80), (_) async {
        if (!_recording) return;
        final level = await widget.voice.amplitude();
        if (!mounted || !_recording) return;
        setState(() => _levels.add(level));
        if (_clock.elapsed >= ChatMessage.maxVoice) unawaited(_send());
      });
    } catch (e) {
      AppLogger.warning('Voice recording did not start', error: e);
      if (mounted) widget.onDone();
    }
  }

  Future<void> _send() async {
    if (_finishing || !_recording) return;
    _finishing = true;
    _recording = false;
    _poll?.cancel();
    _clock.stop();
    final l10n = context.l10n;
    int? ms;
    try {
      ms = await widget.voice.stop();
    } catch (e) {
      AppLogger.warning('Voice recording did not stop', error: e);
    }
    final path = _path;
    if (!mounted) return;
    if (ms == null || path == null || ms < _shortest.inMilliseconds) {
      PopupNotificationService.showError(
        context: context,
        message: l10n.messagesVoiceTooShort,
        position: NotificationPosition.top,
      );
      widget.onDone();
      return;
    }
    widget.onSend(path, ms, VoiceRecorderBar.waveform(_levels));
    widget.onDone();
  }

  Future<void> _cancel() async {
    if (_finishing) return;
    _finishing = true;
    _recording = false;
    _poll?.cancel();
    try {
      await widget.voice.cancel();
    } catch (e) {
      AppLogger.debug('Voice cancel failed: $e');
    }
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _pulse.dispose();
    // Left while recording (e.g. Back): nothing is sent.
    if (_recording) unawaited(widget.voice.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final screen = MediaQuery.sizeOf(context);
    final buttonSize = screen.height * 0.058;
    // The newest levels, right to left, as many as fit.
    final recent = _levels.length > 36
        ? _levels.sublist(_levels.length - 36)
        : _levels;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          screen.width * 0.03,
          8,
          screen.width * 0.03,
          10,
        ),
        child: Row(
          children: [
            _Round(
              size: buttonSize,
              color: palette.surface,
              label: l10n.messagesVoiceCancel,
              onTap: _cancel,
              child: Padding(
                padding: EdgeInsets.all(buttonSize * 0.3),
                child: Image.asset(AppIcons.capsuleClose),
              ),
            ),
            SizedBox(width: screen.width * 0.02),
            Expanded(
              child: Container(
                height: buttonSize,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: AppRadii.lCircular,
                  boxShadow: AppShadows.card(context),
                ),
                child: Row(
                  children: [
                    FadeTransition(
                      opacity: Tween(begin: 0.35, end: 1.0).animate(_pulse),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      liveRegion: true,
                      label:
                          '${l10n.messagesVoiceRecording}, ${ChatTime.clock(_clock.elapsed)}',
                      child: ExcludeSemantics(
                        child: Text(
                          ChatTime.clock(_clock.elapsed),
                          style: TextStyle(
                            fontFamily: kAppFontFamily,
                            fontSize: 16,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomPaint(
                        size: const Size(double.infinity, 28),
                        painter: _LiveLevels(
                          levels: recent,
                          total: _levels.length,
                          color: AppColors.brandGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: screen.width * 0.02),
            _Round(
              size: buttonSize,
              color: AppColors.brandGreen,
              label: l10n.messagesVoiceSend,
              onTap: _send,
              child: Padding(
                padding: EdgeInsets.all(buttonSize * 0.18),
                child: Image.asset(AppIcons.messagesSend),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.size,
    required this.color,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final double size;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: AppPressable(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: AppShadows.card(context),
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// The newest loudness levels as bars from the right edge.
class _LiveLevels extends CustomPainter {
  const _LiveLevels({
    required this.levels,
    required this.total,
    required this.color,
  });

  final List<int> levels;

  /// Levels recorded so far (the window above keeps its length).
  final int total;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const step = 6.0;
    for (var i = 0; i < levels.length; i++) {
      final x = size.width - (levels.length - i) * step + step / 2;
      if (x < 0) continue;
      final level = math.sqrt(levels[i] / 32767);
      final h = math.max(3.0, size.height * level);
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LiveLevels old) =>
      old.total != total || old.color != color;
}
