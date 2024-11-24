import 'package:flutter/material.dart';
import '../core/models/user.dart';
import 'user_avatar.dart';

class UserInfoDisplay extends StatelessWidget {
  final User user;
  final bool showFullInfo;
  final VoidCallback? onTap;
  final double avatarRadius;

  const UserInfoDisplay({
    Key? key,
    required this.user,
    this.showFullInfo = false,
    this.onTap,
    this.avatarRadius = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          UserAvatar(
            imageUrl: user.profileImageUrl,
            radius: avatarRadius,
            fallbackText: user.firstName,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.firstName + "" + user.lastName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (showFullInfo) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (user.studentId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Student ID: ${user.studentId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
