// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/crudModel/repo_crud.dart';
import '../../core/crudModel/user_crud.dart';
import '../../core/models/repo.dart';
import '../codebaseStorage/repository_create.dart';
import '../codebaseStorage/repository_details.dart';
import '../codebaseStorage/repository_edit.dart';

class MyRepository extends StatefulWidget {
  const MyRepository({super.key});

  @override
  State<MyRepository> createState() => _MyRepositoryState();
}

class _MyRepositoryState extends State<MyRepository> {
  @override
  Widget build(BuildContext context) {
    var userProvider = Provider.of<CRUDUser>(context);
    String currentUserId = userProvider.currentUser.id.toString();

    var repoProvider = Provider.of<CRUDRepo>(context);

    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<Repo>>(
            future: repoProvider.fetchItems(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print('Repository Error: ${snapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Failed to load repositories",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});  // Retry loading
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: Text("No data available"));
              }

              List<Repo> userRepos = snapshot.data!
                  .where((repo) => repo.userId == currentUserId)
                  .toList();

              if (userRepos.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "You don't have any repositories yet.\nCreate your very first repository.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18.0),
                        ),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RepositoryPage()),
                            );
                          },
                          child: Text('Add Repository'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: userRepos.length,
                padding: EdgeInsets.all(16.w),
                itemBuilder: (context, index) {
                  return RepositoryCard(
                    repoModel: userRepos[index],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class RepositoryCard extends StatelessWidget {
  final Repo repoModel;

  const RepositoryCard({super.key, required this.repoModel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  RepositoryDetailPage(repository: repoModel)),
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
                  Text(
                    repoModel.name,
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EditRepositoryPage(
                                    repository: repoModel,
                                  )),
                        );
                      } else if (value == 'delete') {
                        _deleteRepository(context, repoModel);
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
              SizedBox(height: 8.0.h),
              Text(repoModel.description),
              SizedBox(height: 8.0.h),
              Row(
                children: <Widget>[
                  Icon(Icons.star, size: 16.0.sp, color: Colors.amber),
                  SizedBox(width: 4.w),
                  Text('5'),
                  SizedBox(width: 16.0.w),
                  Icon(Icons.call_split, size: 16.0.sp, color: Colors.blue),
                  SizedBox(width: 4.0.w),
                  Text('5'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteRepository(BuildContext context, Repo repoModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<bool>(
          future: _hasCollaborators(context, repoModel),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('Delete Repository'),
                content: Center(child: CircularProgressIndicator()),
                actions: <Widget>[
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: Text('Delete Repository'),
                content: Text("Error checking collaborators"),
                actions: <Widget>[
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            }

            return AlertDialog(
              title: Text('Delete Repository'),
              content: Text(
                  'Are you sure you want to delete this repository immediately? This action cannot be undone.'),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Delete'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      await Provider.of<CRUDRepo>(context, listen: false)
                          .removeItem(repoModel.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Repository deleted successfully'),
                        ),
                      );
                    } catch (e) {
                      print('Error deleting repository: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting repository'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _hasCollaborators(
      BuildContext context, Repo repoModel) async {
    try {
      await Provider.of<CRUDRepo>(context, listen: false)
          .getCollaborators(repoModel.id);
      return true;
    } catch (e) {
      print("Error checking collaborators: $e");
      return false;
    }
  }
}
