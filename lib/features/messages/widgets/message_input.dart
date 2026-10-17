import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat.dart';
import '../../../shared/motion/app_motion_widgets.dart';

/// Text field in the app's white input card, with a send button (disabled
/// while empty), when [onPhotoTap] is set a photo button inside the field,
/// and when [onCapsuleTap] is set a button that sends the friend a capsule.
/// The field grows to five lines.
///
/// The text is cleared as soon as it is sent: the message itself appears in
/// the conversation at once and can be retried there if it fails.
class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.onSend,
    this.onCapsuleTap,
    this.onPhotoTap,
    this.onVoiceTap,
    this.onChanged,
    this.focusNode,
  });

  /// While the field is empty, the send button records a voice message.
  final VoidCallback? onVoiceTap;

  /// Every change of the text (the typing hint).
  final ValueChanged<String>? onChanged;

  final void Function(String text) onSend;
  final VoidCallback? onCapsuleTap;
  final VoidCallback? onPhotoTap;

  /// Lets the page put the cursor here (e.g. after choosing Reply).
  final FocusNode? focusNode;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final onCapsuleTap = widget.onCapsuleTap;
    final buttonSize = screen.height * 0.058;

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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (onCapsuleTap != null) ...[
              _RoundButton(
                size: buttonSize,
                color: context.palette.surface,
                tooltip: context.l10n.messagesSendCapsule,
                onTap: onCapsuleTap,
                child: Padding(
                  padding: EdgeInsets.all(buttonSize * 0.14),
                  child: Image.asset(AppIcons.sendCapsule),
                ),
              ),
              SizedBox(width: screen.width * 0.02),
            ],
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: AppRadii.lCircular,
                  boxShadow: AppShadows.card(context),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: widget.focusNode,
                  onChanged: widget.onChanged,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(Chat.maxMessageLength),
                  ],
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: screen.height * 0.021,
                    color: context.palette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.messagesInputHint,
                    hintStyle: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: screen.height * 0.021,
                      color: context.palette.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screen.width * 0.045,
                      vertical: screen.height * 0.015,
                    ),
                    suffixIcon: switch (widget.onPhotoTap) {
                      final onPhotoTap? => Semantics(
                        button: true,
                        label: context.l10n.messagesSendPhoto,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onPhotoTap,
                          child: SizedBox(
                            width: 48,
                            height: 44,
                            child: Center(
                              child: Image.asset(
                                AppIcons.cameraFull,
                                width: 24,
                                height: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      null => null,
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: screen.width * 0.02),
            // Send, or the microphone while there is nothing to send.
            AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.fast),
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: !_hasText && widget.onVoiceTap != null
                  ? _RoundButton(
                      key: const ValueKey('voice'),
                      size: buttonSize,
                      color: AppColors.brandGreen,
                      tooltip: context.l10n.messagesRecordVoice,
                      onTap: widget.onVoiceTap,
                      child: Padding(
                        padding: EdgeInsets.all(buttonSize * 0.22),
                        child: Image.asset(
                          AppIcons.capsuleMicrophone,
                          color: AppColors.onAccent,
                        ),
                      ),
                    )
                  : _RoundButton(
                      key: const ValueKey('send'),
                      size: buttonSize,
                      color: AppColors.brandGreen,
                      tooltip: context.l10n.messagesSend,
                      onTap: _hasText ? _send : null,
                      child: Padding(
                        padding: EdgeInsets.all(buttonSize * 0.18),
                        child: Image.asset(AppIcons.messagesSend),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.size,
    required this.color,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final double size;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: AppPressable(
        enabled: enabled,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.4,
            duration: AppMotion.of(context, AppMotion.standard),
            curve: AppMotion.standardCurve,
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
      ),
    );
  }
}
