import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/crudModel/project_crud.dart';
import '../../core/crudModel/user_crud.dart';
import 'apps/add_app.dart';
import 'codebaseStorage/repository_create.dart';
import 'apps/app_details_view.dart';

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

  String _getGreeting(CRUDUser userProvider) {
    final user = userProvider.currentUser;
    if (user != null) {
      final firstName = user.firstName;
      final lastName = user.lastName;
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return 'Welcome, $firstName $lastName!';
      }
    }
    return 'Welcome to UTB Codebase!';
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<CRUDUser>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
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
                  _getGreeting(userProvider),
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 16.h),
                const Divider(),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    "lib/asset/banner.png",
                    width: MediaQuery.sizeOf(context).width,
                    fit: BoxFit.fitWidth,
                  ),
                ),

                SizedBox(height: 24.h),
                _buildSectionTitle(context, "Services"),
                SizedBox(height: 16.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    "lib/asset/service1.png",
                    width: MediaQuery.sizeOf(context).width,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                SizedBox(height: 16.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    "lib/asset/service2.png",
                    width: MediaQuery.sizeOf(context).width,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                SizedBox(height: 24.h),
                const Divider(),

                SizedBox(height: 24.h),
                _buildSectionTitle(context, 'Quick Access'),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickAccessItem(
                      context: context,
                      icon: Icons.app_shortcut_outlined,
                      label: "Add an App",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddApp(),
                          ),
                        );
                      },
                    ),
                    _buildQuickAccessItem(
                      context: context,
                      icon: Icons.storage_rounded,
                      label: "Add a Repository",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RepositoryPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 24.h),
                const Divider(),
                SizedBox(height: 24.h),

                _buildSectionTitle(context, 'Browse Repositories'),
                SizedBox(height: 16.h),
                _buildCategories(),
                SizedBox(height: 24.h),

                _buildSectionTitle(context, 'Latest Projects'),
                SizedBox(height: 16.h),
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
                        physics: const ClampingScrollPhysics(),
                        itemCount: projectProvider.items.length > 3
                            ? 3
                            : projectProvider.items.length,
                        itemBuilder: (context, index) {
                          final project = projectProvider.items[index];
                          return InkWell(
                            onTap: () async {
                              final owner = await Provider.of<CRUDUser>(context,
                                      listen: false)
                                  .getItemsById(project.userId);

                              if (!context.mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AppDetailsView(
                                    app: project,
                                    appOwner: owner,
                                    userCache: {},
                                    isProjectOwner: owner?.id ==
                                        userProvider.currentUser?.id,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.only(right: 16.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(8.w),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 120.h,
                                      width: 120.w,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: project.logoUrl != null &&
                                                project.logoUrl!.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: project.logoUrl!,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Image.asset(
                                                  'lib/asset/logo.png',
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Image.asset(
                                                'lib/asset/logo.png',
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      project.name,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                SizedBox(height: 24.h),
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
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildQuickAccessItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40.sp,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
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
      spacing: 8.w,
      runSpacing: 8.h,
      children: categories.map((category) {
        return ElevatedButton(
          onPressed: () {
            // Navigate to category-specific project list
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(category),
        );
      }).toList(),
    );
  }
}
