import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:page_transition/page_transition.dart';

class OptionsSettingsRow extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final String? leadingIconPath;
  final bool isLast;
  final bool withDivider;
  final VoidCallback? onTap;
  final Widget? navigateTo;
  final double minVerticalPadding;

  const OptionsSettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.isLast = false,
    this.onTap = null,
    this.navigateTo,
    this.trailing,
    this.leadingIconPath,
    this.minVerticalPadding = 6,
    this.withDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: ListTile(
            dense: true,
            minVerticalPadding: minVerticalPadding,
            visualDensity: VisualDensity(vertical: -3),

            title: DefaultText(
              title,
              textAlign: TextAlign.start,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
              color: isLast ? Color.fromARGB(255, 253, 65, 64) : Colors.black,
            ),
            subtitle: subtitle ?? null,
            leading: leadingIconPath != null
                ? Image.asset(
                    leadingIconPath!,
                    width: screenWidth * 0.09,
                    height: screenWidth * 0.09,
                  )
                : null,
            trailing: isLast
                ? null
                : trailing == null
                ? (Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      'assets/images/icons/prof_page/go_here.png',
                      width: screenWidth * 0.09,
                      height: screenWidth * 0.09,
                    ),
                  ))
                : trailing,
            contentPadding: EdgeInsets.only(
              left: screenWidth * 0.05,
              right: screenWidth * 0.03,
            ),
            onTap: navigateTo != null
                ? () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        duration: const Duration(milliseconds: 10),
                        reverseDuration: const Duration(milliseconds: 10),
                        child: navigateTo,
                      ),
                    );
                  }
                : onTap,
          ),
        ),
        if (!isLast && withDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 0,
            endIndent: 0,
            color: Color.fromARGB(255, 211, 211, 211),
          ),
      ],
    );
  }
}
