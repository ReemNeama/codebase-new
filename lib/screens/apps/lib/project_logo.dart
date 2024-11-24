import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:utb_codebase/screens/apps/lib/lib/shimmer.dart';

class ProjectLogo extends StatelessWidget {
  final String? logoUrl;

  const ProjectLogo({
    Key? key,
    this.logoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: logoUrl != null
            ? CachedNetworkImage(
                imageUrl: logoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerPlaceholder(),
                errorWidget: (context, url, error) =>
                    Image.asset('assets/default_logo.png'),
              )
            : Image.asset('assets/default_logo.png'),
      ),
    );
  }
}
