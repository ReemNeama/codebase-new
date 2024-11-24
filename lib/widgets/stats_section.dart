import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
}

class StatsSection extends StatelessWidget {
  final List<StatItem> stats;
  final EdgeInsets? padding;

  const StatsSection({
    super.key,
    required this.stats,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: padding ?? EdgeInsets.all(16.w),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: stats.map((stat) => _buildStatItem(context, stat)).toList(),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, StatItem stat) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            stat.icon,
            size: 24.sp,
            color: stat.color ?? Theme.of(context).primaryColor,
          ),
          SizedBox(height: 8.h),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: stat.color ?? Theme.of(context).primaryColor,
            ),
          ),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
