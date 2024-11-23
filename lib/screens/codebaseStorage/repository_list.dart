import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../core/crudModel/repo_crud.dart';
import '../../core/models/repo.dart';
import 'repository_details.dart';

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
        } else {
          return _sortAscending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt);
        }
      });

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = (pageKey + newItems.length).toInt();
        _pagingController.appendPage(newItems, nextPageKey);
      }
      _error = null;
    } catch (error) {
      _error = 'Failed to load repositories. Please try again.';
      _pagingController.error = error;
    } finally {
      _isLoading = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return RefreshIndicator(
      onRefresh: () async {
        _pagingController.refresh();
      },
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Expanded(child: _buildSearchBar()),
                SizedBox(width: 8.w),
                IconButton(
                  icon: Icon(
                    Icons.sort,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => _showSortOptions(context),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                _error!,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          Expanded(
            child: _isLoading && _pagingController.itemList == null
              ? Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                )
              : _buildRepositoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Hero(
      tag: 'repo-search-bar',
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search repositories...',
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurfaceVariant,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              if (mounted) {
                setState(() {
                  _searchQuery = value;
                });
                _pagingController.refresh();
              }
            },
          ),
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.sort_by_alpha,
                color: _sortBy == 'name' ? colorScheme.primary : null,
              ),
              title: const Text('Sort by Name'),
              trailing: _sortBy == 'name'
                  ? Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: colorScheme.primary,
                    )
                  : null,
              onTap: () {
                setState(() {
                  if (_sortBy == 'name') {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = 'name';
                    _sortAscending = true;
                  }
                  _pagingController.refresh();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.calendar_today,
                color: _sortBy == 'date' ? colorScheme.primary : null,
              ),
              title: const Text('Sort by Date'),
              trailing: _sortBy == 'date'
                  ? Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: colorScheme.primary,
                    )
                  : null,
              onTap: () {
                setState(() {
                  if (_sortBy == 'date') {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = 'date';
                    _sortAscending = false;
                  }
                  _pagingController.refresh();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepositoryList() {
    return ScreenUtilInit(
      designSize: const Size(414, 896),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth > 600) {
              // Web/Tablet - Grid View
              return PagedGridView<int, Repo>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<Repo>(
                  itemBuilder: (context, item, index) =>
                      RepositoryCard(repoModel: item),
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                padding: const EdgeInsets.all(16),
              );
            } else {
              // Mobile - List View
              return PagedListView<int, Repo>(
                physics: const AlwaysScrollableScrollPhysics(),
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<Repo>(
                  itemBuilder: (context, item, index) =>
                      RepositoryCard(repoModel: item),
                ),
                firstPageErrorIndicatorBuilder: (context) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Something went wrong',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () => _pagingController.refresh(),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
                noItemsFoundIndicatorBuilder: (context) => Center(
                  child: Text(
                    'No repositories found',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

class RepositoryCard extends StatelessWidget {
  final Repo repoModel;

  const RepositoryCard({super.key, required this.repoModel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formattedDate = DateFormat('MMM d, yyyy').format(repoModel.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RepositoryDetailPage(repository: repoModel),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: colorScheme.primary,
                    size: 24.w,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      repoModel.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (repoModel.description.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  repoModel.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16.w,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          formattedDate,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (repoModel.categories.isNotEmpty) ...[
                          Wrap(
                            spacing: 4.w,
                            runSpacing: 4.h,
                            alignment: WrapAlignment.end,
                            children: repoModel.categories.map((category) => 
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  category,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                          SizedBox(height: 4.h),
                        ],
                        if (repoModel.languages.isNotEmpty)
                          Wrap(
                            spacing: 4.w,
                            runSpacing: 4.h,
                            alignment: WrapAlignment.end,
                            children: repoModel.languages.map((language) => 
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  language,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
