// // lib/screens/project/project_list_screen.dart

// // ignore_for_file: use_build_context_synchronously

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/project_provider.dart';
// import '../../providers/user_provider.dart';
// import '../../widgets/project/project_card.dart';
// import '../../constants/app_strings.dart';
// import '../../models/project.dart';
// import '../../utils/exceptions.dart';

// class ProjectListScreen extends StatefulWidget {
//   const ProjectListScreen({Key? key}) : super(key: key);

//   @override
//   State<ProjectListScreen> createState() => _ProjectListScreenState();
// }

// class _ProjectListScreenState extends State<ProjectListScreen> {
//   final ScrollController _scrollController = ScrollController();
//   String _searchQuery = '';
//   bool _showGraduationOnly = false;
//   String _sortBy = 'date';
//   bool _sortAscending = false;
//   bool _isLoading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _fetchProjects();
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchProjects() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _error = null;
//       });

//       final userProvider = context.read<UserProvider>();
//       if (userProvider.user == null) {
//         throw FirebaseAuthenticationException('User not authenticated');
//       }

//       await context.read<ProjectProvider>().fetchProjects();
//     } on FirebaseAuthenticationException catch (e) {
//       setState(() => _error = e.message);
//       Navigator.pushReplacementNamed(context, '/login');
//     } catch (e) {
//       setState(() => _error = e.toString());
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   void _onSearchChanged(String value) {
//     setState(() {
//       _searchQuery = value;
//     });
//   }

//   void _onSortChanged(String? value) {
//     if (value != null) {
//       setState(() {
//         if (_sortBy == value) {
//           _sortAscending = !_sortAscending;
//         } else {
//           _sortBy = value;
//           _sortAscending = true;
//         }
//       });
//     }
//   }

//   List<Project> _filterAndSortProjects(List<Project> projects) {
//     var filteredProjects = projects.where((project) {
//       if (_showGraduationOnly && !project.isGraduation) {
//         return false;
//       }
//       return project.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           project.description
//               .toLowerCase()
//               .contains(_searchQuery.toLowerCase());
//     }).toList();

//     filteredProjects.sort((a, b) {
//       int comparison;
//       switch (_sortBy) {
//         case 'name':
//           comparison = a.name.compareTo(b.name);
//           break;
//         case 'status':
//           comparison = a.status.compareTo(b.status);
//           break;
//         case 'date':
//         default:
//           comparison = b.updatedAt.compareTo(a.updatedAt);
//           break;
//       }
//       return _sortAscending ? comparison : -comparison;
//     });

//     return filteredProjects;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;
//     final textTheme = Theme.of(context).textTheme;

//     if (_isLoading) {
//       return Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(
//             color: colorScheme.primary,
//           ),
//         ),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.error_outline,
//                 size: 64,
//                 color: colorScheme.error,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 _error!,
//                 style: textTheme.bodyLarge?.copyWith(
//                   color: colorScheme.error,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               FilledButton.tonal(
//                 onPressed: _fetchProjects,
//                 child: const Text('Retry'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(AppStrings.projects),
//         leading: const Image(
//           image: AssetImage("assets/logo.png"),
//           width: 150,
//           height: 150,
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: () => Navigator.pushNamed(context, '/project/create')
//                 .then((_) => _fetchProjects()),
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _fetchProjects,
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   TextField(
//                     onChanged: _onSearchChanged,
//                     decoration: InputDecoration(
//                       hintText: AppStrings.search,
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       DropdownButton<String>(
//                         value: _sortBy,
//                         items: const [
//                           DropdownMenuItem(
//                             value: 'date',
//                             child: Text('Sort by Date'),
//                           ),
//                           DropdownMenuItem(
//                             value: 'name',
//                             child: Text('Sort by Name'),
//                           ),
//                           DropdownMenuItem(
//                             value: 'status',
//                             child: Text('Sort by Status'),
//                           ),
//                         ],
//                         onChanged: _onSortChanged,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: FilterChip(
//                           label: const Text('Graduation Projects Only'),
//                           selected: _showGraduationOnly,
//                           onSelected: (value) {
//                             setState(() => _showGraduationOnly = value);
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Consumer<ProjectProvider>(
//                 builder: (context, projectProvider, _) {
//                   final projects =
//                       _filterAndSortProjects(projectProvider.allprojects);

//                   if (projects.isEmpty) {
//                     return Center(
//                       child: Text(
//                         _searchQuery.isEmpty
//                             ? AppStrings.noResults
//                             : 'No projects match your search',
//                         style: textTheme.bodyLarge,
//                       ),
//                     );
//                   }

//                   return ListView.builder(
//                     controller: _scrollController,
//                     padding: const EdgeInsets.all(16),
//                     itemCount: projects.length,
//                     itemBuilder: (context, index) {
//                       final project = projects[index];
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 16),
//                         child: ProjectCard(
//                           project: project,
//                           onTap: () => Navigator.pushNamed(
//                             context,
//                             '/project/detail',
//                             arguments: {'projectId': project.id},
//                           ).then((_) => _fetchProjects()),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
