import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/core/theme/app_text_styles.dart';
import 'package:later/shared/widgets/app_sheets.dart';
import 'package:later/shared/widgets/buttons/default_green_button.dart';

/// A capsule's words stay short (the owner's limit; the rules still accept
/// up to 2000 from older versions).
const int maxDescriptionLength = 200;

/// The description on the capsule card: what is written so far (three
/// lines of it); a tap opens the composer, a roomy field with a counter (B4).
class CapsuleCreationDescriptionInputField extends StatelessWidget {
  final TextEditingController controller;

  const CapsuleCreationDescriptionInputField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: l10n.capsulesCreationDescriptionHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // The title gave its focus back when the composer closed and
          // the keyboard jumped up on it.
          FocusManager.instance.primaryFocus?.unfocus();
          DescriptionComposer.show(context, controller);
        },
        child: ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: double.infinity,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final text = controller.text.trim();
                  return Text(
                    text.isEmpty ? l10n.capsulesCreationDescriptionHint : text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 14,
                      height: 1.3,
                      color: text.isEmpty
                          ? context.palette.textMuted
                          : context.palette.textPrimary,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The description written in a sheet that rises with the keyboard.
class DescriptionComposer extends StatelessWidget {
  const DescriptionComposer({super.key, required this.controller});

  final TextEditingController controller;

  static Future<void> show(
    BuildContext context,
    TextEditingController controller,
  ) => showOnKeyboard<void>(
    context,
    DescriptionComposer(controller: controller),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSheets.radius),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SheetHandle()),
              Text(
                l10n.capsulesComposerTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.pageTitle(context).copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.35,
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 4,
                  maxLines: null,
                  maxLength: maxDescriptionLength,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(maxDescriptionLength),
                  ],
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 17,
                    height: 1.35,
                    color: palette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.capsulesCreationDescriptionHint,
                    hintStyle: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 17,
                      color: palette.textMuted,
                    ),
                    border: InputBorder.none,
                    counterStyle: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.12),
                child: DefaultGreenButton(
                  onTap: () => Navigator.of(context).pop(),
                  text: l10n.capsulesComposerDone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
