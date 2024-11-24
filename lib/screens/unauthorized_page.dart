import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../core/auth/auth_provider.dart';

class UnauthorizedPage extends StatelessWidget {
  final String? message;
  final VoidCallback? onBackPressed;

  const UnauthorizedPage({
    Key? key,
    this.message,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unauthorized Access'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.gpp_bad_outlined,
                    size: 80.sp,
                    color: theme.colorScheme.error,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  message ?? 'You don\'t have permission to access this resource',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 32.h),
                _buildActionButtons(context),
                SizedBox(height: 16.h),
                _buildHelpSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Go Back'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(200.w, 48.h),
          ),
        ),
        SizedBox(height: 12.h),
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.state.isAuthenticated) {
              return TextButton.icon(
                onPressed: () {
                  // Navigate to login page
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
                style: TextButton.styleFrom(
                  minimumSize: Size(200.w, 48.h),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'If you believe this is an error, please contact your administrator or support team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 12.h),
          TextButton.icon(
            onPressed: () {
              // TODO: Implement support contact
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support contact feature coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.support_agent),
            label: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}
