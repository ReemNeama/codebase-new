// ignore_for_file: prefer_final_fields, prefer_const_constructors, prefer_const_constructors_in_immutables, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/crudModel/user_crud.dart';
import '../../core/crudModel/project_crud.dart';
import '../../core/crudModel/comment_crud.dart';
import '../../widget/programming_languages.dart';
import '../../widget/skills.dart';
import '../../core/models/project.dart';
import '../../core/models/repo.dart';
import '../../core/models/comment.dart';
import '../../core/crudModel/repo_crud.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Fetch user data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CRUDUser>().getCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<CRUDUser>();
    final user = userProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data
          await Future.wait([
            context.read<CRUDUser>().getCurrentUser(),
            context.read<CRUDProject>().fetchItems(),
            context.read<CRUDRepo>().fetchItems(),
            context.read<CRUDComment>().fetchComments(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user.profileImageUrl != null &&
                                user.profileImageUrl!.isNotEmpty
                            ? NetworkImage(user.profileImageUrl!)
                            : const NetworkImage(
                                "https://placehold.jp/150x150.png",
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FutureBuilder<List<Project>>(
                            future: context.read<CRUDProject>().fetchItems(),
                            builder: (context, projectSnapshot) {
                              final projectCount = projectSnapshot.hasData
                                  ? projectSnapshot.data!
                                      .where((project) =>
                                          project.userId == user.id)
                                      .length
                                  : 0;
                              return InfoCard(
                                label: 'Projects',
                                value: projectCount.toString(),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          FutureBuilder<List<Repo>>(
                            future: context.read<CRUDRepo>().fetchItems(),
                            builder: (context, repoSnapshot) {
                              final repoCount = repoSnapshot.hasData
                                  ? repoSnapshot.data!
                                      .where((repo) =>
                                          repo.userId == user.id ||
                                          repo.collabs.contains(user.id))
                                      .length
                                  : 0;
                              return InfoCard(
                                label: 'Repositories',
                                value: repoCount.toString(),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                TabSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String label;
  final String value;

  InfoCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class TabSection extends StatelessWidget {
  const TabSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Review'),
              Tab(text: 'Information'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          ),
          Expanded(
            child: TabBarView(
              children: [
                ReviewTab(),
                InformationTab(
                    isEditing: false,
                    onProfileUpdate: (bio, skills, languages) {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<CRUDUser>();
    final currentUser = userProvider.currentUser;
    final projectProvider = context.watch<CRUDProject>();
    final commentProvider = context.watch<CRUDComment>();

    return FutureBuilder<List<Project>>(
      future: projectProvider.fetchItems(),
      builder: (context, projectSnapshot) {
        if (projectSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (projectSnapshot.hasError) {
          return Center(
            child: Text(
              'Error loading projects: ${projectSnapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final projects = projectSnapshot.data ?? [];
        final userProjects =
            projects.where((p) => p.userId == currentUser.id).toList();
        if (userProjects.isEmpty) {
          return const Center(
            child: Text('No projects found'),
          );
        }

        final projectIds = userProjects.map((p) => p.id).toList();

        return FutureBuilder<List<Comment>>(
          future: Future.wait(
            projectIds.map((id) => commentProvider.getCommentsByProjectId(id))
          ).then((lists) => lists.expand((list) => list).toList()),
          builder: (context, commentSnapshot) {
            if (commentSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (commentSnapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading comments: ${commentSnapshot.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }

            final comments = commentSnapshot.data ?? [];

            if (comments.isEmpty) {
              return const Center(
                child: Text('No reviews yet'),
              );
            }

            return ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                final project = userProjects.firstWhere(
                  (p) => p.id == comment.projectId,
                  orElse: () => Project(
                    id: '',
                    userId: '',
                    name: 'Unknown Project',
                    description: '',
                    screenshotsUrl: [],
                    status: 'Unknown',
                    isGraduation: false,
                    collaborators: [],
                    downloadUrls: {},
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    category: 'Unknown',
                  ),
                );

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(
                                currentUser.profileImageUrl ?? "https://placehold.jp/150x150.png",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.name,
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
                        const SizedBox(height: 10),
                        Text(
                          'Review by ${comment.userId}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < (comment.rating) ? Icons.star : Icons.star_border,
                              size: 14,
                              color: index < (comment.rating) ? Colors.amber : Colors.grey,
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(comment.content),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
        //return FutureBuilder<List<Comment>>(
        //  future: Future.wait(
        //    projectIds.map((id) => commentProvider.getCommentsByProjectId(id))
        //  ).then((lists) => lists.expand((list) => list).toList()),
        //  builder: (context, commentSnapshot) {
        //    if (commentSnapshot.connectionState == ConnectionState.waiting) {
        //      return const Center(child: CircularProgressIndicator());
        //    }

        //    if (commentSnapshot.hasError) {
        //      return Center(
        //        child: Text(
        //          'Error loading comments: ${commentSnapshot.error}',
        //          style: TextStyle(color: Theme.of(context).colorScheme.error),
        //        ),
        //      );
        //    }

        //    final comments = commentSnapshot.data ?? [];

        //    if (comments.isEmpty) {
        //      return const Center(
        //        child: Text('No reviews yet'),
        //      );
        //    }

        //    return ListView.builder(
        //      itemCount: comments.length,
        //      itemBuilder: (context, index) {
        //        final comment = comments[index];
        //        final project = userProjects.firstWhere(
        //          (p) => p.id == comment.projectId,
        //          orElse: () => Project(
        //            id: '',
        //            userId: '',
        //            name: 'Unknown Project',
        //            description: '',
        //            screenshotsUrl: [],
        //            status: 'Unknown',
        //            isGraduation: false,
        //            collaborators: [],
        //            downloadUrls: {},
        //            createdAt: DateTime.now(),
        //            updatedAt: DateTime.now(),
        //            category: 'Unknown',
        //          ),
        //        );

        //        return Card(
        //          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        //          child: Padding(
        //            padding: const EdgeInsets.all(16),
        //            child: Column(
        //              crossAxisAlignment: CrossAxisAlignment.start,
        //              children: [
        //                Row(
        //                  children: [
        //                    CircleAvatar(
        //                      backgroundImage: NetworkImage(
        //                        currentUser.profileImageUrl ?? "https://placehold.jp/150x150.png",
        //                      ),
        //                    ),
        //                    const SizedBox(width: 10),
        //                    Expanded(
        //                      child: Column(
        //                        crossAxisAlignment: CrossAxisAlignment.start,
        //                        children: [
        //                          Text(
        //                            project.name,
        //                            style: Theme.of(context).textTheme.titleMedium,
        //                          ),
        //                          Text(
        //                            _formatDate(comment.createdAt),
        //                            style: Theme.of(context).textTheme.bodySmall,
        //                          ),
        //                        ],
        //                      ),
        //                    ),
        //                  ],
        //                ),
        //                const SizedBox(height: 10),
        //                Text(
        //                  'Review by ${comment.userId}',
        //                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        //                    fontWeight: FontWeight.bold,
        //                  ),
        //                ),
        //                const SizedBox(height: 4),
        //                Row(
        //                  children: List.generate(5, (index) {
        //                    return Icon(
        //                      index < (comment.rating) ? Icons.star : Icons.star_border,
        //                      size: 14,
        //                      color: index < (comment.rating) ? Colors.amber : Colors.grey,
        //                    );
        //                  }),
        //                ),
        //                const SizedBox(height: 8),
        //                Text(comment.content),
        //              ],
        //            ),
        //          ),
        //        );
        //      },
        //    );
        //  },
        //);
      },
    );
  }
}

class InformationTab extends StatefulWidget {
  final bool isEditing;
  final Function(String bio, List<String> skills, List<String> languages)
      onProfileUpdate;

  const InformationTab({
    super.key,
    required this.isEditing,
    required this.onProfileUpdate,
  });

  @override
  State<InformationTab> createState() => _InformationTabState();
}

class _InformationTabState extends State<InformationTab> {
  late TextEditingController _bioController;
  List<String> _selectedSkills = [];
  List<String> _selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    final user = Provider.of<CRUDUser>(context, listen: false).currentUser;
    _bioController.text = user.bio ?? '';
    _selectedSkills = List<String>.from(user.skills);
    _selectedLanguages = List<String>.from(user.programmingLanguages);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InformationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isEditing && oldWidget.isEditing) {
      widget.onProfileUpdate(
        _bioController.text,
        _selectedSkills,
        _selectedLanguages,
      );
    }
  }

  Widget _buildSkillSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Skills:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: availableSkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return FilterChip(
              label: Text(skill),
              selected: isSelected,
              onSelected: widget.isEditing
                  ? (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSkills.add(skill);
                        } else {
                          _selectedSkills.remove(skill);
                        }
                      });
                    }
                  : null,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Programming Languages:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: availableProgrammingLanguages.map((language) {
            final isSelected = _selectedLanguages.contains(language);
            return FilterChip(
              label: Text(language),
              selected: isSelected,
              onSelected: widget.isEditing
                  ? (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLanguages.add(language);
                        } else {
                          _selectedLanguages.remove(language);
                        }
                      });
                    }
                  : null,
              selectedColor: Colors.red[100],
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected ? Colors.red : null,
              ),
              checkmarkColor: Colors.red,
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _bioController,
              enabled: widget.isEditing,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
                hintText: 'Tell us about yourself...',
              ),
            ),
            const SizedBox(height: 16),
            _buildSkillSelection(),
            const SizedBox(height: 16),
            _buildLanguageSelection(),
          ],
        ),
      ),
    );
  }
}
