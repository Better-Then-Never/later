import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/default_buttons/default_text_button.dart';
import 'package:later/views/widgets/profile/profile_page_divider.dart';

class ProfilePageMyCapsulesPanel extends StatelessWidget {
  const ProfilePageMyCapsulesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: const DefaultText(
            "My capsules",
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: screenWidth - 32,
          height: 80,
          decoration: BoxDecorations.whiteCard(),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        'assets/images/icons/prof_page/my_capsules.png',
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 65,
                top: 0,
                right: 20,
                child: SizedBox(
                  height: 39,
                  child: DefaultTextButton(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/camera',
                        arguments: {'privacy': 'friends'},
                      );
                    },
                    text: 'Add to map | Only for friends',
                  ),
                ),
              ),

              Positioned(
                left: 65,
                top: 39,
                right: 20,
                child: ProfilePageDivider(width: screenWidth - 32),
              ),

              Positioned(
                left: 65,
                bottom: 0,
                right: 20,
                child: SizedBox(
                  height: 41,
                  child: DefaultTextButton(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/camera',
                        arguments: {'privacy': 'public'},
                      );
                    },
                    text: 'Add to map | Everyone',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
