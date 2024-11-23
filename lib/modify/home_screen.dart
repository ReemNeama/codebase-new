// // ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../constants/app_strings.dart';
// import '../../providers/user_provider.dart';
// import '../../providers/project_provider.dart';
// import '../../widgets/common/custom_app_bar.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Fetch projects when the screen initializes
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userProvider = Provider.of<UserProvider>(context);
//     final projectProvider = Provider.of<ProjectProvider>(context);

//     return Scaffold(
//       appBar: const CustomAppBar(
//         title: "UTB Codebase",
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Greeting
//               Text(
//                 '${AppStrings.welcome}, ${userProvider.user?.firstName} ${userProvider.user?.lastName}!',
//                 style: Theme.of(context).textTheme.headlineSmall,
//               ),
//               const SizedBox(height: 10),
//               const Divider(),

//               Image.asset(
//                 "assets/banner.png",
//                 width: MediaQuery.sizeOf(context).width,
//                 fit: BoxFit.fitWidth,
//               ),

//               _buildSectionTitle(context, "Services"),
//               Image.asset(
//                 "assets/service1.png",
//                 width: MediaQuery.sizeOf(context).width,
//                 fit: BoxFit.fitWidth,
//               ),
//               Image.asset(
//                 "assets/service2.png",
//                 width: MediaQuery.sizeOf(context).width,
//                 fit: BoxFit.fitWidth,
//               ),
//               const Divider(),
//               // Categories

//               _buildSectionTitle(context, 'Quick Access'),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Column(
//                     children: [
//                       IconButton(
//                           onPressed: () {
//                             Navigator.pushNamed(context, '/project/create');
//                           },
//                           icon: Icon(
//                             Icons.app_shortcut_outlined,
//                             size: 40,
//                           )),
//                       Text(
//                         "Add an App",
//                         style: TextStyle(
//                             color: Colors.black, fontWeight: FontWeight.w400),
//                       )
//                     ],
//                   ),
//                   Column(
//                     children: [
//                       IconButton(
//                           onPressed: () {
//                             Navigator.pushNamed(context, '/repo/create');
//                           },
//                           icon: Icon(
//                             Icons.storage_rounded,
//                             size: 40,
//                           )),
//                       Text(
//                         "Add a Repository",
//                         style: TextStyle(
//                             color: Colors.black, fontWeight: FontWeight.w400),
//                       )
//                     ],
//                   ),
//                 ],
//               ),

//               const Divider(),
//               _buildSectionTitle(context, 'Browse Repositories'),
//               _buildCategories(),
//               const SizedBox(height: 16),
//               // Popular Projects
//               _buildSectionTitle(context, 'Latest Projects'),
//               _buildPopularProjects(projectProvider),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(BuildContext context, String title) {
//     return Text(
//       title,
//       style: Theme.of(context).textTheme.headlineSmall,
//     );
//   }

//   Widget _buildCategories() {
//     final categories = [
//       'Web',
//       'Mobile',
//       'AI',
//       'Data Science',
//       'Game Development'
//     ];
//     return Wrap(
//       spacing: 16,
//       runSpacing: 16,
//       children: categories.map((category) {
//         return ElevatedButton(
//           onPressed: () {
//             // Navigate to category-specific project list
//           },
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//           ),
//           child: Text(category),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildPopularProjects(ProjectProvider projectProvider) {
//     return SizedBox(
//       height: 200,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         shrinkWrap: true,
//         physics: NeverScrollableScrollPhysics(),
//         itemCount: projectProvider.allprojects.length > 3
//             ? 3
//             : projectProvider.allprojects.length,
//         itemBuilder: (context, index) {
//           final project = projectProvider.allprojects[index];
//           return InkWell(
//             onTap: () => Navigator.pushNamed(
//               context,
//               '/project/detail',
//               arguments: {'projectId': project.id},
//             ),
//             child: Padding(
//               padding: const EdgeInsets.only(left: 5),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   SizedBox(
//                     height: 110,
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(8.0),
//                       child: Image.network(
//                         project.logoUrl ?? "",
//                         width: 110,
//                         fit: BoxFit.fitWidth,
//                       ),
//                     ),
//                   ),
//                   Text(
//                     project.name,
//                     style: TextStyle(
//                         color: Colors.black, fontWeight: FontWeight.bold),
//                   )
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
