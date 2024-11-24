// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, library_private_types_in_public_api

import '/screens/myProjects/my_apps.dart';
import 'package:flutter/material.dart';
import 'my_repo.dart';

class MyProjects extends StatefulWidget {
  const MyProjects({super.key});

  @override
  State<MyProjects> createState() => _MyProjectsState();
}

class _MyProjectsState extends State<MyProjects> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          PreferredSize(
            preferredSize: Size.fromHeight(48.0),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                tabs: [
                  Tab(text: 'My Repository'),
                  Tab(text: 'My Apps'),
                ],
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                MyRepository(),
                MyApps(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
