import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class DetailHeader extends StatelessWidget {
  final String title;
  final String description;
  final DateTime createdAt;
  final List<String>? languages;
  final List<String>? categories;
  final String? status;
  final Widget? logo;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const DetailHeader({
    Key? key,
    required this.title,
    required this.description,
    required this.createdAt,
    this.languages,
    this.categories,
    this.status,
    this.logo,
    this.actions,
    this.backgroundColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerColor = backgroundColor ?? theme.primaryColor;
    final textColor = theme.colorScheme.onPrimary;

    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: padding ?? EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (logo != null) ...[
            Center(child: logo!),
            SizedBox(height: 10),
          ],
          Text(
            'Created on ${DateFormat('MMM d, y').format(createdAt)}',
            style: TextStyle(
              fontSize: 14.sp,
              color: textColor.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 16.sp,
              color: textColor,
            ),
          ),
          if (languages != null && languages!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(
              'Languages',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: languages!
                  .map((lang) => Chip(
                        label: Text(lang),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ))
                  .toList(),
            ),
          ],
          if (categories != null && categories!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: categories!
                  .map((category) => Chip(
                        label: Text(category),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ))
                  .toList(),
            ),
          ],
          if (status != null) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(
                  Icons.public,
                  color: textColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  status!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ],
          if (actions != null) ...[
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
