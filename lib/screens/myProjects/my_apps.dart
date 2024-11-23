// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/crudModel/project_crud.dart';
import '../../core/crudModel/user_crud.dart';
import '../../core/models/project.dart';  
import '../apps/add_app.dart' ;  
import '../apps/edit_app.dart';
import '../apps/app_details.dart';

class MyApps extends StatefulWidget {
  const MyApps({super.key});

  @override
  _MyAppsState createState() => _MyAppsState();
}

class _MyAppsState extends State<MyApps> {
  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<CRUDProject>(context);
    final userProvider = Provider.of<CRUDUser>(context);

    return FutureBuilder<List<Project>>(
      future: projectProvider.fetchItems(),  
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        List<Project> projects = snapshot.data!.where((project) =>
            project.userId == userProvider.currentUser.id).toList();

        if (projects.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "You don't have any apps yet.\n Create your very first app.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddApp()),
                      );
                    },
                    child: Text('Add App'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            return AppCard(
              project: projects[index],
              onDelete: () async {
                bool confirmed = await _confirmDelete(context);
                if (confirmed) {
                  await projectProvider.removeItem(projects[index].id);
                  setState(() {}); // Refresh the UI after deletion
                }
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this app?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    ) ??
        false;
  }
}

class AppCard extends StatelessWidget {
  final Project project;  
  final VoidCallback onDelete;  

  const AppCard({
    super.key,  
    required this.project,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    // Assuming status is always published for now
    String status = "Published";

    switch (status) {
      case 'Published':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = 'Published';
        break;
      case 'Pending':
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'Rejected':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AppDetailPage(app: project)),
        );
      },
      child: Card(
        color: Colors.grey[200],
        elevation: 4.0,
        margin: EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'Edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EditApp(
                                    existingProject: project,
                                  )),
                        );
                      } else if (value == 'Delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return {'Edit', 'Delete'}.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList();
                    },
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Text(project.description),
              SizedBox(height: 8.0),
              Row(
                children: <Widget>[
                  Icon(statusIcon, size: 16.0.sp, color: statusColor),
                  SizedBox(width: 4.w),
                  Text(statusText, style: TextStyle(color: statusColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
