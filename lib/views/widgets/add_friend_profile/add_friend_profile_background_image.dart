import 'package:flutter/material.dart';
import 'package:later/services/firebase_storage_service.dart';
import 'package:later/views/widgets/_common/default_elements/default_loading_container.dart';

class AddFriendProfileBackgroundImage extends StatelessWidget {
  final String userId;
  final double width;
  final double height;

  const AddFriendProfileBackgroundImage({
    super.key,
    required this.userId,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(25),
        bottomRight: Radius.circular(25),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: FutureBuilder<String?>(
          future: FirebaseStorageService.getBackgroundImageUrl(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return DefaultLoadingContainer(
                width: width,
                height: height,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              return Image.network(
                snapshot.data!,
                width: width,
                height: height,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return DefaultLoadingContainer(
                    width: width,
                    height: height,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey[500],
                    ),
                  );
                },
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
