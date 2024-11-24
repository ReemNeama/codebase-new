import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool isEditable;
  final Function(int)? onRatingChanged;

  const StarRating({
    Key? key,
    required this.rating,
    this.size = 14,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.isEditable = false,
    this.onRatingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: isEditable && onRatingChanged != null 
            ? () => onRatingChanged!(index + 1)
            : null,
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            size: size.sp,
            color: index < rating ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}
