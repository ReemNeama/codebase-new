import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_network/image_network.dart';
import 'package:utb_codebase/screens/apps/app_details_view.dart';
import '../../core/models/project.dart';
import 'add_app.dart';

class AppStorePage extends StatefulWidget {
  const AppStorePage({super.key});

  @override
  State<AppStorePage> createState() => _AppStorePageState();
}

class _AppStorePageState extends State<AppStorePage> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _sortAscending = false;
  String _sortBy = 'date';
  bool _isLoading = true;
  String? _error;

  final List<String> _categories = [
    'All',
    'Restaurant and Food Delivery',
    'Educational',
    'Lifestyle',
    'Social Media',
    'Game',
    'Productivity',
    'Business',
    'Healthcare',
    'Pet Care',
    'Grocery Delivery',
    'Finance',
    'Travel',
    'Cooking',
    'Fitness',
    'Entertainment',
    'Photo and Video Editing',
    'Utility',
    'Libraries and Demo',
    'Parenting',
    'Social Networking',
    'Music',
    'Sports',
    'Kids'
  ];

  @override
  void initState() {
    super.initState();
    _fetchApps();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchApps() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      // The actual fetching is handled by the StreamBuilder
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _onCategoryChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedCategory = value;
      });
    }
  }

  void _onSortChanged(String? value) {
    if (value != null) {
      setState(() {
        if (_sortBy == value) {
          _sortAscending = !_sortAscending;
        } else {
          _sortBy = value;
          _sortAscending = true;
        }
      });
    }
  }

  List<QueryDocumentSnapshot> _filterAndSortApps(
      List<QueryDocumentSnapshot> apps) {
    var filteredApps = apps.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      var appName = data['name']?.toLowerCase() ?? '';
      var description = data['description']?.toLowerCase() ?? '';
      var category = data['category']?.toLowerCase() ?? '';

      return (_selectedCategory == 'All' ||
              category == _selectedCategory.toLowerCase()) &&
          (appName.contains(_searchQuery.toLowerCase()) ||
              description.contains(_searchQuery.toLowerCase()));
    }).toList();

    filteredApps.sort((a, b) {
      var dataA = a.data() as Map<String, dynamic>;
      var dataB = b.data() as Map<String, dynamic>;
      int comparison;

      switch (_sortBy) {
        case 'name':
          comparison = (dataA['name'] ?? '').compareTo(dataB['name'] ?? '');
          break;
        case 'category':
          comparison =
              (dataA['category'] ?? '').compareTo(dataB['category'] ?? '');
          break;
        case 'date':
        default:
          comparison =
              (dataB['updatedAt'] ?? '').compareTo(dataA['updatedAt'] ?? '');
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filteredApps;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            SizedBox(height: 16.h),
            Text(
              _error!,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            FilledButton.tonal(
              onPressed: _fetchApps,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Store'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddApp(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchApps,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search apps...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _onSearchChanged(''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(
                            value: 'date',
                            child: Text('Sort by Date'),
                          ),
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('Sort by Name'),
                          ),
                          DropdownMenuItem(
                            value: 'category',
                            child: Text('Sort by Category'),
                          ),
                        ],
                        onChanged: _onSortChanged,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          items: _categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: _onCategoryChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('project')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No apps available'
                            : 'No apps match your search',
                        style: textTheme.bodyLarge,
                      ),
                    );
                  }

                  final filteredDocs = _filterAndSortApps(snapshot.data!.docs);

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      var doc = filteredDocs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      String appName = data['name'] ?? 'No Name';
                      String description =
                          data['description'] ?? 'No Description';
                      String category = data['category'] ?? 'No Category';
                      String imageUrl =
                          data['logoUrl'] ?? 'https://via.placeholder.com/150';
                      String docId = doc.id;

                      return Card(
                        color: Colors.grey[200],
                        elevation: 4,
                        margin: EdgeInsets.only(bottom: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: SizedBox(
                            width: 48.w,
                            height: 48.h,
                            child: ImageNetwork(
                              image: imageUrl,
                              height: 48,
                              width: 48,
                              fitAndroidIos: BoxFit.cover,
                              fitWeb: BoxFitWeb.cover,
                            ),
                          ),
                          title: Text(
                            appName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category: $category',
                                style: TextStyle(color: colorScheme.primary),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8.h,
                            horizontal: 16.w,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AppDetailsView(
                                  app: Project.fromMap(data, docId),
                                  appOwner: null,
                                  userCache: const {},
                                  isProjectOwner: false,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
