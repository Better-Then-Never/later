import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';

class OptionsSettingsRow extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final bool isLast;
  final VoidCallback? onTap;
  final Widget? navigateTo;

  const OptionsSettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.isLast = false,
    this.onTap = null,
    this.navigateTo,
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
            minVerticalPadding: 6,
            visualDensity: VisualDensity(vertical: -3),

            title: DefaultText(
              title,
              textAlign: TextAlign.start,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
              color: isLast ? Color.fromARGB(255, 253, 65, 64) : Colors.black,
            ),
            subtitle: subtitle ?? null,
            trailing: isLast
                ? null
                : Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      'assets/images/icons/prof_page/go_here.png',
                      width: screenWidth * 0.09,
                      height: screenWidth * 0.09,
                    ),
                  ),
            contentPadding: EdgeInsets.only(
              left: screenWidth * 0.05,
              right: screenWidth * 0.03,
            ),
            onTap: navigateTo != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => navigateTo!),
                    );
                  }
                : onTap,
          ),
        ),
        if (!isLast)
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
