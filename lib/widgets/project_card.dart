import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/models/project.dart';
import '../core/models/repo.dart';
import 'star_rating.dart';

class ProjectCard extends StatelessWidget {
  final dynamic project; // Can be Project or Repo
  final Function()? onTap;
  final Function()? onEdit;
  final Function()? onDelete;
  final List<Widget>? extraActions;

  const ProjectCard({
    Key? key,
    required this.project,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.extraActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isRepo = project is Repo;
    final String name = isRepo ? (project as Repo).name : (project as Project).name;
    final String description = isRepo ? (project as Repo).description : (project as Project).description;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2.0,
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return {'edit', 'delete'}.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(choice.toUpperCase()),
                          );
                        }).toList();
                      },
                    ),
                ],
              ),
              SizedBox(height: 8.0),
              Text(description),
              SizedBox(height: 8.0),
              Row(
                children: [
                  if (isRepo) ...[
                    Icon(Icons.star, size: 16.0.sp, color: Colors.amber),
                    SizedBox(width: 4.w),
                    Text('5'),
                    SizedBox(width: 16.0.w),
                    Icon(Icons.call_split, size: 16.0.sp, color: Colors.blue),
                    SizedBox(width: 4.0.w),
                    Text('5'),
                  ] else ...[
                    Icon(Icons.check_circle, size: 16.0.sp, color: Colors.green),
                    SizedBox(width: 4.w),
                    Text('Published'),
                  ],
                  if (extraActions != null) ...extraActions!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
