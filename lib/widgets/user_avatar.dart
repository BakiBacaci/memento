import 'package:flutter/material.dart';

import '../theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.photoUrl,
    this.initial,
    this.radius = 20,
    this.onTap,
  });

  final String? photoUrl;
  final String? initial;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface,
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              (initial == null || initial!.isEmpty)
                  ? 'M'
                  : initial!.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: AppColors.gold,
                fontSize: radius * 0.8,
                fontFamily: kSerif,
              ),
            ),
    );

    if (onTap == null) return avatar;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: avatar,
    );
  }
}
