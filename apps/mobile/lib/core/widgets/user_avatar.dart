import 'package:flutter/material.dart';

/// Reusable Neo-Brutalist Avatar widget that gracefully handles
/// local assets (such as Notion-style avatar templates) and remote URLs,
/// always maintaining a solid black border and white canvas background.
class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final double size;
  final double borderWidth;
  final Color borderColor;
  final Color backgroundColor;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    this.size = 40.0,
    this.borderWidth = 2.0,
    this.borderColor = Colors.black,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAsset = avatarUrl.startsWith('assets/');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ClipOval(
        child: isAsset
            ? Image.asset(
                avatarUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/avatars/avatar_1.png',
                    fit: BoxFit.cover,
                  );
                },
              )
            : Image.network(
                avatarUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/avatars/avatar_1.png',
                    fit: BoxFit.cover,
                  );
                },
              ),
      ),
    );
  }
}
