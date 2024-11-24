import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GallerySection extends StatelessWidget {
  final List<String> images;
  final String title;
  final double? imageHeight;
  final VoidCallback? onAddImage;
  final Function(String)? onRemoveImage;
  final bool canModify;

  const GallerySection({
    super.key,
    required this.images,
    this.title = 'Gallery',
    this.imageHeight,
    this.onAddImage,
    this.onRemoveImage,
    this.canModify = false,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty && !canModify) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.all(16.w),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canModify && onAddImage != null)
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate),
                    onPressed: onAddImage,
                    tooltip: 'Add Image',
                  ),
              ],
            ),
            if (images.isNotEmpty) ...[
              SizedBox(height: 16.h),
              SizedBox(
                height: imageHeight ?? 200.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: imageHeight ?? 200.h,
                          margin: EdgeInsets.only(right: 16.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                            ),
                          ),
                        ),
                        if (canModify && onRemoveImage != null)
                          Positioned(
                            top: 8.h,
                            right: 24.w,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.white),
                                onPressed: () => onRemoveImage?.call(images[index]),
                                tooltip: 'Remove Image',
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
