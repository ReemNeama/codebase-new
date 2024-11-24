import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? fallbackText;

  const UserAvatar({
    Key? key,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.fallbackText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? NetworkImage(imageUrl!)
          : const NetworkImage("https://placehold.jp/150x150.png"),
      child: imageUrl == null || imageUrl!.isEmpty
          ? (fallbackText != null && fallbackText!.isNotEmpty
              ? Text(fallbackText![0].toUpperCase())
              : null)
          : null,
    );
  }
}
