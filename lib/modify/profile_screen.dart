// import 'package:codebase/widgets/common/programming_languages.dart';
// import 'package:codebase/widgets/common/skills.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../models/project.dart';
// import '../../models/comment.dart';
// import '../../models/user.dart';
// import '../../providers/comment_provider.dart';
// import '../../providers/user_provider.dart';
// import '../../providers/project_provider.dart';
// import '../../providers/repo_provider.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({Key? key}) : super(key: key);

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   bool _isEditing = false;
//   void _handleLogout() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: Text(
//               'Logout',
//               style: TextStyle(color: Theme.of(context).colorScheme.error),
//             ),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true && mounted) {
//       await context.read<UserProvider>().logout();
//       if (mounted) {
//         Navigator.pushReplacementNamed(context, '/login');
//       }
//     }
//   }

//   Future<void> _handleProfileUpdate(
//       String bio, List<String> skills, List<String> languages) async {
//     setState(() => _isEditing = false);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Row(
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(width: 16),
//             Text('Updating profile...'),
//           ],
//         ),
//         duration: Duration(seconds: 1),
//       ),
//     );

//     try {
//       final userProvider = context.read<UserProvider>();
//       final currentUser = userProvider.user;
//       if (currentUser == null) throw Exception('No user logged in');

//       final updatedUser = currentUser.copyWith(
//         bio: bio,
//         skills: skills,
//         programmingLanguages: languages,
//       );

//       await userProvider.updateProfile(updatedUser);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Profile updated successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isEditing = true); // Revert to edit mode on error
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to update profile: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _toggleEditing() {
//     setState(() {
//       _isEditing = !_isEditing;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = context.watch<UserProvider>().user;

//     if (user == null) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         leading: const Image(
//           image: AssetImage("assets/logo.png"),
//           width: 150,
//           height: 150,
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(_isEditing ? Icons.save : Icons.edit),
//             onPressed: _isEditing
//                 ? () => _handleProfileUpdate(
//                       user.bio ?? '',
//                       user.skills,
//                       user.programmingLanguages,
//                     )
//                 : _toggleEditing,
//           ),
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _handleLogout,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Center(
//           child: Column(
//             children: [
//               CircleAvatar(
//                 radius: 50,
//                 backgroundImage: user.profileImageUrl != null
//                     ? NetworkImage(user.profileImageUrl!)
//                     : const NetworkImage(
//                         "https://placehold.jp/150x150.png",
//                       ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 '${user.firstName} ${user.lastName}',
//                 style: Theme.of(context).textTheme.headlineSmall,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 user.email,
//                 style: Theme.of(context).textTheme.bodyLarge,
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   FutureBuilder<int?>(
//                     future:
//                         context.read<ProjectProvider>().projectValue(user.id),
//                     builder: (context, projectSnapshot) {
//                       return InfoCard(
//                         label: 'Projects',
//                         value: projectSnapshot.hasData
//                             ? projectSnapshot.data.toString()
//                             : '0',
//                       );
//                     },
//                   ),
//                   const SizedBox(width: 10),
//                   FutureBuilder<int?>(
//                     future: context.read<RepoProvider>().repoCount(user.id),
//                     builder: (context, repoSnapshot) {
//                       return InfoCard(
//                         label: 'Repositories',
//                         value: repoSnapshot.hasData
//                             ? repoSnapshot.data.toString()
//                             : '0',
//                       );
//                     },
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               TabSection(
//                 isEditing: _isEditing,
//                 onProfileUpdate: _handleProfileUpdate,
//               ),
//               const SizedBox(height: 10),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class TabSection extends StatelessWidget {
//   final bool isEditing;
//   final Function(String bio, List<String> skills, List<String> languages)
//       onProfileUpdate;

//   const TabSection({
//     super.key,
//     required this.isEditing,
//     required this.onProfileUpdate,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 2,
//       child: Column(
//         children: [
//           TabBar(
//             tabs: const [
//               Tab(text: 'Review'),
//               Tab(text: 'Information'),
//             ],
//             indicatorColor: Colors.red[700],
//             labelColor: Colors.red[700],
//             unselectedLabelColor: Colors.black,
//           ),
//           SizedBox(
//             height: 250,
//             child: TabBarView(
//               children: [
//                 const ReviewTab(),
//                 InformationTab(
//                   isEditing: isEditing,
//                   onProfileUpdate: onProfileUpdate,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class InformationTab extends StatefulWidget {
//   final bool isEditing;
//   final Function(String bio, List<String> skills, List<String> languages)
//       onProfileUpdate;

//   const InformationTab({
//     super.key,
//     required this.isEditing,
//     required this.onProfileUpdate,
//   });

//   @override
//   State<InformationTab> createState() => _InformationTabState();
// }

// class _InformationTabState extends State<InformationTab> {
//   late TextEditingController _bioController;
//   List<String> _selectedSkills = [];
//   List<String> _selectedLanguages = [];

//   @override
//   void initState() {
//     super.initState();
//     _bioController = TextEditingController();
//     final user = context.read<UserProvider>().user;
//     if (user != null) {
//       _bioController.text = user.bio ?? '';
//       _selectedSkills = List<String>.from(user.skills);
//       _selectedLanguages = List<String>.from(user.programmingLanguages);
//     }
//   }

//   @override
//   void dispose() {
//     _bioController.dispose();
//     super.dispose();
//   }

//   @override
//   void didUpdateWidget(InformationTab oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (!widget.isEditing && oldWidget.isEditing) {
//       widget.onProfileUpdate(
//         _bioController.text,
//         _selectedSkills,
//         _selectedLanguages,
//       );
//     }
//   }

//   Widget _buildSkillSelection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Select Skills:',
//           style: Theme.of(context).textTheme.titleMedium,
//         ),
//         const SizedBox(height: 8),
//         Wrap(
//           spacing: 8,
//           runSpacing: 4,
//           children: availableSkills.map((skill) {
//             final isSelected = _selectedSkills.contains(skill);
//             return FilterChip(
//               label: Text(skill),
//               selected: isSelected,
//               onSelected: widget.isEditing
//                   ? (selected) {
//                       setState(() {
//                         if (selected) {
//                           _selectedSkills.add(skill);
//                         } else {
//                           _selectedSkills.remove(skill);
//                         }
//                       });
//                     }
//                   : null,
//               selectedColor: Theme.of(context).chipTheme.selectedColor,
//               backgroundColor: Theme.of(context).chipTheme.backgroundColor,
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildLanguageSelection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Select Programming Languages:',
//           style: Theme.of(context).textTheme.titleMedium,
//         ),
//         const SizedBox(height: 8),
//         Wrap(
//           spacing: 8,
//           runSpacing: 4,
//           children: availableProgrammingLanguages.map((language) {
//             final isSelected = _selectedLanguages.contains(language);
//             return FilterChip(
//               label: Text(language),
//               selected: isSelected,
//               onSelected: widget.isEditing
//                   ? (selected) {
//                       setState(() {
//                         if (selected) {
//                           _selectedLanguages.add(language);
//                         } else {
//                           _selectedLanguages.remove(language);
//                         }
//                       });
//                     }
//                   : null,
//               selectedColor: Theme.of(context).chipTheme.selectedColor,
//               backgroundColor: Theme.of(context).chipTheme.backgroundColor,
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: _bioController,
//               enabled: widget.isEditing,
//               maxLines: 3,
//               decoration: const InputDecoration(
//                 labelText: 'Bio',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildSkillSelection(),
//             const SizedBox(height: 16),
//             _buildLanguageSelection(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class InfoCard extends StatelessWidget {
//   final String label;
//   final String value;

//   const InfoCard({
//     super.key,
//     required this.label,
//     required this.value,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         children: [
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ReviewTab extends StatelessWidget {
//   const ReviewTab({super.key});

//   String _formatDate(DateTime date) {
//     return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = context.watch<UserProvider>().user;
//     if (currentUser == null) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return FutureBuilder<void>(
//         future: context
//             .read<ProjectProvider>()
//             .fetchCurrentUserProjects(currentUser.id),
//         builder: (context, projectSnapshot) {
//           if (projectSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (projectSnapshot.hasError) {
//             return Center(
//               child: Text(
//                 'Error loading projects: ${projectSnapshot.error}',
//                 style: TextStyle(color: Theme.of(context).colorScheme.error),
//               ),
//             );
//           }

//           final projects = context.read<ProjectProvider>().projects;
//           final projectIds = projects.map((p) => p.id).toList();

//           return FutureBuilder<List<Comment>>(
//             future: context
//                 .read<CommentProvider>()
//                 .fetchCommentsForProjects(projectIds),
//             builder: (context, commentSnapshot) {
//               if (commentSnapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (commentSnapshot.hasError) {
//                 return Center(
//                   child: Text(
//                     'Error loading comments: ${commentSnapshot.error}',
//                     style:
//                         TextStyle(color: Theme.of(context).colorScheme.error),
//                   ),
//                 );
//               }

//               final comments = commentSnapshot.data ?? [];

//               if (comments.isEmpty) {
//                 return const Center(
//                   child: Text('No comments yet'),
//                 );
//               }

//               return ListView.builder(
//                 itemCount: comments.length,
//                 itemBuilder: (context, index) {
//                   final comment = comments[index];
//                   if (projectSnapshot.hasError) {
//                     return const Center(
//                       child: Text('Error loading project details'),
//                     );
//                   }

//                   return FutureBuilder<Project?>(
//                     future: context
//                         .read<ProjectProvider>()
//                         .fetchProjectById(comment.projectId),
//                     builder: (context, projectSnapshot) {
//                       if (projectSnapshot.connectionState ==
//                           ConnectionState.waiting) {
//                         return const Center(child: CircularProgressIndicator());
//                       }

//                       if (projectSnapshot.hasError) {
//                         return const Card(
//                           child: Padding(
//                             padding: EdgeInsets.all(16),
//                             child: Text('Error loading project details'),
//                           ),
//                         );
//                       }

//                       final project = projectSnapshot.data ??
//                           Project(
//                             id: '',
//                             name: 'Unknown Project',
//                             description: '',
//                             userId: '',
//                             status: 'Unknown',
//                             isGraduation: false,
//                             collaborators: [],
//                             tags: [],
//                             screenshotsUrl: [],
//                             downloadCounts: {},
//                             createdAt: DateTime.now(),
//                             updatedAt: DateTime.now(),
//                           );

//                       return Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   CircleAvatar(
//                                     backgroundImage: NetworkImage(
//                                         currentUser.profileImageUrl ??
//                                             "https://placehold.jp/150x150.png"),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           project.name,
//                                           style: Theme.of(context)
//                                               .textTheme
//                                               .titleMedium,
//                                         ),
//                                         Text(
//                                           _formatDate(comment.createdAt),
//                                           style: Theme.of(context)
//                                               .textTheme
//                                               .bodySmall,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               FutureBuilder<User?>(
//                                 future: context
//                                     .read<UserProvider>()
//                                     .getUserById(comment.userId),
//                                 builder: (context, userSnapshot) {
//                                   final commentAuthor = userSnapshot.data;
//                                   return Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       if (commentAuthor != null)
//                                         Text(
//                                           'Review by ${commentAuthor.fullName}',
//                                           style: Theme.of(context)
//                                               .textTheme
//                                               .bodyMedium
//                                               ?.copyWith(
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                         ),
//                                       const SizedBox(height: 4),
//                                       Row(
//                                         children: List.generate(5, (index) {
//                                           return Icon(
//                                             index < comment.stars
//                                                 ? Icons.star
//                                                 : Icons.star_border,
//                                             size: 14,
//                                             color: index < comment.stars
//                                                 ? Colors.amber
//                                                 : Colors.grey,
//                                           );
//                                         }),
//                                       ),
//                                     ],
//                                   );
//                                 },
//                               ),
//                               const SizedBox(height: 8),
//                               Text(comment.content),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         });
//   }
// }
