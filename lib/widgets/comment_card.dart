import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/models/comment.dart';
import '../core/models/user.dart';
import 'star_rating.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final User? user;
  final String projectName;
  final bool showProject;
  final Function()? onTap;

  const CommentCard({
    Key? key,
    required this.comment,
    this.user,
    required this.projectName,
    this.showProject = false,
    this.onTap,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      user?.profileImageUrl ?? "https://placehold.jp/150x150.png",
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showProject)
                          Text(
                            projectName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        Text(
                          _formatDate(comment.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Review by ${user?.firstName ?? comment.userFirstName} ${user?.lastName ?? comment.userLastName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              StarRating(rating: comment.stars),
              SizedBox(height: 8),
              Text(
                comment.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
