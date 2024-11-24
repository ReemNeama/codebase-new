import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/crudModel/project_crud.dart';
import '../../core/crudModel/user_crud.dart';
import 'apps/add_app.dart';
import 'codebaseStorage/repository_create.dart';
import 'apps/app_details.dart'; // Added import for AppDetailPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Fetch projects when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CRUDProject>(context, listen: false).fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<CRUDUser>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh user data and projects
          await userProvider.getCurrentUser();
          await Provider.of<CRUDProject>(context, listen: false).fetchItems();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  'Welcome, ${userProvider.currentUser.firstName} ${userProvider.currentUser.lastName}!',
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.h),
                const Divider(),

                Image.asset(
                  "lib/asset/banner.png",
                  width: MediaQuery.sizeOf(context).width,
                  fit: BoxFit.fitWidth,
                ),

                _buildSectionTitle(context, "Services"),
                Image.asset(
                  "lib/asset/service1.png",
                  width: MediaQuery.sizeOf(context).width,
                  fit: BoxFit.fitWidth,
                ),
                Image.asset(
                  "lib/asset/service2.png",
                  width: MediaQuery.sizeOf(context).width,
                  fit: BoxFit.fitWidth,
                ),
                const Divider(),

                _buildSectionTitle(context, 'Quick Access'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddApp(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.app_shortcut_outlined,
                              size: 40,
                            )),
                        const Text(
                          "Add an App",
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w400),
                        )
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RepositoryPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.storage_rounded,
                              size: 40,
                            )),
                        const Text(
                          "Add a Repository",
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w400),
                        )
                      ],
                    ),
                  ],
                ),

                const Divider(),
                _buildSectionTitle(context, 'Browse Repositories'),
                _buildCategories(),
                SizedBox(height: 16.h),
                _buildSectionTitle(context, 'Latest Projects'),
                Consumer<CRUDProject>(
                  builder: (context, projectProvider, _) {
                    if (projectProvider.items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          child: Text(
                            'No apps have been published yet',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: projectProvider.items.length > 3
                            ? 3
                            : projectProvider.items.length,
                        itemBuilder: (context, index) {
                          final project = projectProvider.items[index];
                          return InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AppDetailPage(app: project),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(left: 5.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  SizedBox(
                                    height: 110.h,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: project.logoUrl != null &&
                                              project.logoUrl!.isNotEmpty
                                          ? Image.network(
                                              project.logoUrl!,
                                              width: 110.w,
                                              fit: BoxFit.fitWidth,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  'lib/asset/logo.png',
                                                  width: 110.w,
                                                  fit: BoxFit.fitWidth,
                                                );
                                              },
                                            )
                                          : Image.asset(
                                              'lib/asset/logo.png',
                                              width: 110.w,
                                              fit: BoxFit.fitWidth,
                                            ),
                                    ),
                                  ),
                                  Text(
                                    project.name,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCategories() {
    final categories = [
      'Web',
      'Mobile',
      'AI',
      'Data Science',
      'Game Development'
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: categories.map((category) {
        return ElevatedButton(
          onPressed: () {
            // Navigate to category-specific project list
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(category),
        );
      }).toList(),
    );
  }
}
