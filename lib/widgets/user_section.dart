import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/models/user.dart';

class UserSection extends StatelessWidget {
  final User owner;
  final List<User> collaborators;
  final String title;
  final VoidCallback? onAddCollaborator;
  final Function(User)? onRemoveCollaborator;
  final bool canModify;

  const UserSection({
    super.key,
    required this.owner,
    required this.collaborators,
    this.title = 'Team',
    this.onAddCollaborator,
    this.onRemoveCollaborator,
    this.canModify = false,
  });

  @override
  Widget build(BuildContext context) {
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
                if (canModify && onAddCollaborator != null)
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: onAddCollaborator,
                    tooltip: 'Add Collaborator',
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildUserTile(
              context,
              owner,
              'Owner',
              showRemoveButton: false,
            ),
            if (collaborators.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Text(
                'Collaborators',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              ...collaborators.map((user) => _buildUserTile(
                    context,
                    user,
                    'Collaborator',
                    showRemoveButton: canModify && onRemoveCollaborator != null,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    User user,
    String role, {
    bool showRemoveButton = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child:
                user.photoUrl == null ? Text(user.name[0].toUpperCase()) : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (showRemoveButton)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => onRemoveCollaborator?.call(user),
              color: Colors.red,
              tooltip: 'Remove Collaborator',
            ),
        ],
      ),
    );
  }
}
