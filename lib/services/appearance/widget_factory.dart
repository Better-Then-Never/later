import 'package:flutter/material.dart';

class WidgetFactory {
  static Widget buildUserAvatar({
    required String? imageUrl,
    required double radius,
    String? fallbackAsset = 'assets/images/icons/navbar/icon-profile.png',
  }) {
    ImageProvider avatar;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      avatar = NetworkImage(imageUrl);
    } else {
      avatar = AssetImage(fallbackAsset!);
    }
    
    return CircleAvatar(
      radius: radius,
      backgroundImage: avatar,
      backgroundColor: Colors.grey[200],
    );
  }
  
  static Widget buildLoadingContainer({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.grey[600],
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
  
  static Widget buildUserListTile({
    required String name,
    required String username,
    required String? imageUrl,
    required double screenWidth,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        vertical: 0,
        horizontal: screenWidth * 0.02,
      ),
      leading: buildUserAvatar(imageUrl: imageUrl, radius: screenWidth * 0.07),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: screenWidth * 0.045,
          fontFamily: 'Irina',
          color: Colors.black,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '@$username',
        style: TextStyle(
          fontSize: screenWidth * 0.040,
          fontFamily: 'Irina',
          color: Color.fromARGB(255, 94, 94, 94),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}