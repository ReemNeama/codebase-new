import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../core/crudModel/repo_crud.dart';
import '../../core/models/repo.dart';
import 'repository_details.dart';
import 'repository_create.dart';
import '../../widgets/project_card.dart';

class RepositoryList extends StatefulWidget {
  const RepositoryList({super.key});

  @override
  State<RepositoryList> createState() => _RepositoryListState();
}

class _RepositoryListState extends State<RepositoryList> {
  String _searchQuery = '';
  String? _error;
  static const _pageSize = 20;
  final PagingController<int, Repo> _pagingController =
      PagingController(firstPageKey: 0);
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      if (!mounted) return;
      var repoProvider = Provider.of<CRUDRepo>(context, listen: false);

      // First, get the base items
      final newItems = await repoProvider.fetchPaginatedItems(
        pageSize: _pageSize,
        orderBy: _sortBy,
      );

      // If there's a search query, filter the items
      var filteredItems = _searchQuery.isEmpty
          ? newItems
          : newItems
              .where((repo) =>
                  repo.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  (repo.description?.toLowerCase() ?? '')
                      .contains(_searchQuery.toLowerCase()))
              .toList();

      if (!mounted) return;
      if (filteredItems.isEmpty && pageKey == 0) {
        setState(() {
          _error = 'No repositories found';
        });
        return;
      }

      // Apply sorting
      filteredItems.sort((a, b) {
        if (_sortBy == 'name') {
          return _sortAscending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name);
        } else if (_sortBy == 'date') {
          return _sortAscending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt);
        }
        return 0;
      });

      final isLastPage = filteredItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(filteredItems);
      } else {
        final nextPageKey = pageKey + filteredItems.length;
        _pagingController.appendPage(filteredItems, nextPageKey);
      }

      if (!mounted) return;
      setState(() {
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      final errorMessage = error is Exception
          ? error.toString()
          : 'An unexpected error occurred while loading repositories';

      setState(() {
        _error = errorMessage;
      });
      _pagingController.error = errorMessage;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _onSortChanged(String? value) {
    if (value != null && value != _sortBy) {
      setState(() {
        _sortBy = value;
        _pagingController.refresh();
      });
    }
  }

  void _onSortDirectionChanged(bool? value) {
    if (value != null && value != _sortAscending) {
      setState(() {
        _sortAscending = value;
        _pagingController.refresh();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repositories'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search repositories...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _pagingController.refresh();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('Name'),
                    ),
                    DropdownMenuItem(
                      value: 'date',
                      child: Text('Date'),
                    ),
                  ],
                  onChanged: _onSortChanged,
                ),
                IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  onPressed: () => _onSortDirectionChanged(!_sortAscending),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: EdgeInsets.all(8.0.w),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => Future.sync(
                () => _pagingController.refresh(),
              ),
              child: PagedListView<int, Repo>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<Repo>(
                  itemBuilder: (context, repo, index) => ProjectCard(
                    project: repo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RepositoryDetailPage(repository: repo),
                        ),
                      );
                    },
                    extraActions: [
                      const Icon(Icons.star, size: 16.0, color: Colors.amber),
                      SizedBox(width: 4.w),
                      const Text('5'),
                      SizedBox(width: 16.0.w),
                      const Icon(Icons.call_split,
                          size: 16.0, color: Colors.blue),
                      SizedBox(width: 4.0.w),
                      const Text('5'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
