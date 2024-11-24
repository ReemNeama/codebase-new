import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../core/crudModel/repo_crud.dart';
import '../../core/models/repo.dart';
import 'repository_details.dart';
import 'repository_create.dart';

class RepositoryList extends StatefulWidget {
  const RepositoryList({super.key});

  @override
  State<RepositoryList> createState() => _RepositoryListState();
}

class _RepositoryListState extends State<RepositoryList> {
  String _searchQuery = '';
  bool _isLoading = false;
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
      _isLoading = true;
      var repoProvider = Provider.of<CRUDRepo>(context, listen: false);
      final newItems = await repoProvider.fetchPaginatedItems(
        pageKey,
        _pageSize,
        searchQuery: _searchQuery,
      );

      // Apply sorting
      newItems.sort((a, b) {
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

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
      _pagingController.error = error;
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
              //Navigator.push(
              //  context,
              //  MaterialPageRoute(
              //    builder: (context) => const create(),
              //  ),
              //);
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
                style: TextStyle(color: Colors.red),
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
                  itemBuilder: (context, repo, index) => RepositoryCard(
                    repository: repo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RepositoryDetailPage(repository: repo),
                        ),
                      );
                    },
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

class RepositoryCard extends StatelessWidget {
  final Repo repository;
  final VoidCallback onTap;

  const RepositoryCard({
    Key? key,
    required this.repository,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            repository.name.substring(0, 1).toUpperCase(),
          ),
        ),
        title: Text(repository.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (repository.description != null &&
                repository.description!.isNotEmpty)
              Text(
                repository.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 4.h),
            Text(
              'Created: ${DateFormat('MMM d, yyyy').format(repository.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}
