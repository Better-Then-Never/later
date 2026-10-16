import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/chat.dart';

/// Text field with a send button and, when [onCapsuleTap] is set, a camera
/// button that sends the friend a capsule.
///
/// [onSend] returns whether the message was sent; the text is kept when it
/// was not, so nothing typed is lost.
class MessageInput extends StatefulWidget {
  const MessageInput({super.key, required this.onSend, this.onCapsuleTap});

  final Future<bool> Function(String text) onSend;
  final VoidCallback? onCapsuleTap;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _sending = false;

  static const _sendGreen = Color(0xFF6FCF47);

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    // Cleared right away so a fast typist can go on; restored on failure.
    _controller.clear();
    final sent = await widget.onSend(text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (!sent && _controller.text.isEmpty) _controller.text = text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: BorderSide(color: color, width: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final onCapsuleTap = widget.onCapsuleTap;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screen.width * 0.04,
        vertical: screen.height * 0.01,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (onCapsuleTap != null) ...[
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.grey200,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'Send a capsule',
                  icon: Icon(
                    Icons.camera_alt_rounded,
                    size: screen.height * 0.03,
                    color: AppColors.brandGreen,
                  ),
                  onPressed: onCapsuleTap,
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(width: screen.width * 0.02),
            ],
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(Chat.maxMessageLength),
                ],
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  hintStyle: TextStyle(
                    color: AppColors.grey500,
                    fontSize: screen.height * 0.02,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screen.width * 0.04,
                    vertical: screen.height * 0.015,
                  ),
                  border: _border(AppColors.grey300),
                  enabledBorder: _border(AppColors.grey300),
                  focusedBorder: _border(AppColors.grey400),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            SizedBox(width: screen.width * 0.02),
            Container(
              decoration: const BoxDecoration(
                color: _sendGreen,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'Send',
                icon: Image.asset(
                  AppIcons.messagesSend,
                  width: screen.height * 0.06,
                  height: screen.height * 0.06,
                ),
                onPressed: _sending ? null : _send,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
