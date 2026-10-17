import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../chat_time.dart';
import '../voice_player.dart';

/// A voice message in its bubble: play / pause, the loudness bars (filled
/// as it plays; tap or drag them to jump) and the time. [onGreen]: on the
/// user's own green bubble (white tones).
class VoiceMessageView extends StatelessWidget {
  const VoiceMessageView({
    super.key,
    required this.message,
    required this.onGreen,
  });

  final ChatMessage message;
  final bool onGreen;

  /// Width of the bars on a [screenWidth] screen.
  static double barsWidth(double screenWidth) => screenWidth * 0.42;

  @override
  Widget build(BuildContext context) {
    final id = message.id;
    final (playing, loading, progress, position) = context
        .select<VoicePlayer, (bool, bool, double, int)>(
          (p) => (
            p.isPlaying(id),
            p.isLoading(id),
            p.progressOf(id),
            p.positionOf(id),
          ),
        );
    final l10n = context.l10n;
    final palette = context.palette;
    final duration = message.durationMs ?? 0;
    final shown = playing || position > 0 ? position : duration;
    final width = barsWidth(MediaQuery.sizeOf(context).width);
    final strong = onGreen ? AppColors.onAccent : AppColors.brandGreen;
    final faint = onGreen
        ? AppColors.onAccent.withAlpha(0x66)
        : palette.iconMuted.withAlpha(0x88);
    final ready = message.delivery != MessageDelivery.sending;

    Future<void> toggle() async {
      final ok = await context.read<VoicePlayer>().toggle(message);
      if (!ok && context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: l10n.messagesVoiceFailed,
          position: NotificationPosition.top,
        );
      }
    }

    void seekAt(double dx) => context.read<VoicePlayer>().seek(id, dx / width);

    return Semantics(
      label:
          '${l10n.messagesVoice}, ${ChatTime.clock(Duration(milliseconds: duration))}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            button: true,
            label: playing ? l10n.messagesPauseVoice : l10n.messagesPlayVoice,
            child: GestureDetector(
              onTap: ready ? toggle : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: strong,
                  shape: BoxShape.circle,
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: onGreen
                              ? AppColors.brandGreen
                              : AppColors.onAccent,
                        ),
                      )
                    : CustomPaint(
                        painter: _PlayPausePainter(
                          playing: playing,
                          color: onGreen
                              ? AppColors.brandGreen
                              : AppColors.onAccent,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => seekAt(d.localPosition.dx),
                  onHorizontalDragUpdate: (d) => seekAt(d.localPosition.dx),
                  child: CustomPaint(
                    size: Size(width, 28),
                    painter: _BarsPainter(
                      bars: message.waveform,
                      progress: progress,
                      played: strong,
                      rest: faint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ChatTime.clock(Duration(milliseconds: shown)),
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 11,
                  color: onGreen ? AppColors.onMediaMuted : palette.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayPausePainter extends CustomPainter {
  const _PlayPausePainter({required this.playing, required this.color});

  final bool playing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final c = size.center(Offset.zero);
    if (playing) {
      const w = 4.0;
      const h = 14.0;
      for (final dx in [-5.0, 5.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c + Offset(dx, 0), width: w, height: h),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
    } else {
      // A triangle a little right of centre (it looks centred).
      final path = Path()
        ..moveTo(c.dx - 4.5, c.dy - 8)
        ..lineTo(c.dx + 8.5, c.dy)
        ..lineTo(c.dx - 4.5, c.dy + 8)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PlayPausePainter old) =>
      old.playing != playing || old.color != color;
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter({
    required this.bars,
    required this.progress,
    required this.played,
    required this.rest,
  });

  final List<int> bars;
  final double progress;
  final Color played;
  final Color rest;

  @override
  void paint(Canvas canvas, Size size) {
    const count = ChatMessage.waveformBars;
    final gap = size.width / count;
    final barWidth = math.max(1.5, gap * 0.55);
    for (var i = 0; i < count; i++) {
      // A message without bars (or with fewer) shows a quiet line.
      final level = bars.isEmpty
          ? 8
          : bars[(i * bars.length / count).floor().clamp(0, bars.length - 1)];
      final h = math.max(3.0, size.height * level / 100);
      final x = gap * i + gap / 2;
      final paint = Paint()
        ..color = (i + 0.5) / count <= progress ? played : rest
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2 + barWidth / 2),
        Offset(x, size.height / 2 + h / 2 - barWidth / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.progress != progress ||
      old.played != played ||
      old.rest != rest ||
      !identical(old.bars, bars);
}
