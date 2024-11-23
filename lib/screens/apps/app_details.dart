// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print, prefer_const_constructors, prefer_final_fields, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/crudModel/user_crud.dart';
import '../../core/models/project.dart';
import '../../core/crudModel/comment_crud.dart';
import '../../core/models/comment.dart';
import '../../core/models/user.dart';

class AppDetailPage extends StatefulWidget {
  final Project app;

  const AppDetailPage({super.key, required this.app});

  @override
  _AppDetailPageState createState() => _AppDetailPageState();
}

class _AppDetailPageState extends State<AppDetailPage> {
  final _formKey = GlobalKey<FormState>();
  String _comment = '';
  double _rating = 3.0;
  final _commentCrud = CRUDComment();
  final _userCrud = CRUDUser();

  List<Comment> _comments = [];
  Map<String, User?> _userCache = {};
  User? _appOwner;
  bool _isSubmitting = false;
  bool _hasUserReviewed = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _fetchAppOwner();
    _checkUserReview();
  }

  Future<void> _checkUserReview() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final hasReviewed = await _commentCrud.hasUserCommentedOnProject(
        user.uid,
        widget.app.id,
      );
      setState(() {
        _hasUserReviewed = hasReviewed;
      });
    }
  }

  Future<void> _fetchAppOwner() async {
    try {
      final owner = await _userCrud.getItemsById(widget.app.userId);
      setState(() {
        _appOwner = owner;
      });
    } catch (e) {
      print('Error fetching app owner: $e');
    }
  }

  // Function to fetch comments
  void _fetchComments() async {
    try {
      final comments = await _commentCrud.getCommentsByProjectId(widget.app.id);
      setState(() {
        _comments = comments;
      });
      _fetchUsersForComments(comments);
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<void> _fetchUsersForComments(List<Comment> comments) async {
    for (var comment in comments) {
      if (!_userCache.containsKey(comment.userId)) {
        try {
          final user = await _userCrud.getItemsById(comment.userId);
          setState(() {
            _userCache[comment.userId] = user;
          });
        } catch (e) {
          print('Error fetching user ${comment.userId}: $e');
        }
      }
    }
  }

  Future<void> _submitComment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        _formKey.currentState!.save();
        final user = firebase_auth.FirebaseAuth.instance.currentUser!;
        
        // Check if user has already reviewed
        final hasReviewed = await _commentCrud.hasUserCommentedOnProject(
          user.uid,
          widget.app.id,
        );

        if (hasReviewed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already reviewed this app'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final comment = Comment(
          id: '',
          userId: user.uid,
          userFirstName: user.displayName?.split(' ').first ?? '',
          userLastName: user.displayName?.split(' ').last ?? '',
          projectId: widget.app.id,
          content: _comment,
          stars: _rating.round(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _commentCrud.addComment(comment);
        
        // Reset form and refresh comments
        _formKey.currentState!.reset();
        setState(() {
          _rating = 3.0;
          _hasUserReviewed = true;
        });
        
        _fetchComments();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error submitting comment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit review. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Function to display screenshots in a dialog

  bool _isProjectOwner() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    return currentUser != null && widget.app.userId == currentUser.uid;
  }


  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          widget.app.name,
          style: const TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_isProjectOwner())
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                // Add functionality to edit app details
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section with App Logo and Basic Info
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                children: [
                  Hero(
                    tag: 'app_logo_${widget.app.id}',
                    child: Container(
                      height: 120,
                      width: 120,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: widget.app.logoUrl != null
                            ? Image.network(
                                widget.app.logoUrl!,
                                fit: BoxFit.cover,
                              )
                            : Image.asset('assets/default_logo.png'),
                      ),
                    ),
                  ),
                  Text(
                    widget.app.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            // Description Section
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.app.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                    if (widget.app.category.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(widget.app.category),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // App Owner & Collaborators Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Team',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: _appOwner != null 
                          ? Text(
                              _appOwner!.firstName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white),
                      ),
                      title: const Text(
                        'App Owner',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        _appOwner != null 
                          ? '${_appOwner!.firstName} ${_appOwner!.lastName}'
                          : 'Loading...',
                      ),
                    ),
                    if (widget.app.collaborators.isNotEmpty) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Collaborators',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.app.collaborators.length,
                        itemBuilder: (context, index) {
                          final collaborator = widget.app.collaborators[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              child: Text(
                                collaborator[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(collaborator),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Screenshots Section
            if (widget.app.screenshotsUrl.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Screenshots',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.app.screenshotsUrl.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          Container(
                                            constraints: BoxConstraints(
                                              maxHeight: MediaQuery.of(context).size.height * 0.8,
                                              maxWidth: MediaQuery.of(context).size.width * 0.9,
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                widget.app.screenshotsUrl[index],
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                            onPressed: () => Navigator.of(context).pop(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.app.screenshotsUrl[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            // Additional Details Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Published',
                      DateFormat('dd/MM/yyyy').format(widget.app.createdAt),
                    ),
                    if (_isProjectOwner())
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Add functionality to download app
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Download',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Reviews Section
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reviews',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (firebase_auth.FirebaseAuth.instance.currentUser != null &&
                        firebase_auth.FirebaseAuth.instance.currentUser?.uid != widget.app.userId &&
                        !_hasUserReviewed)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rate this app',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _rating = index + 1.0;
                                    });
                                  },
                                  icon: Icon(
                                    index < _rating.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Theme.of(context).primaryColor,
                                    size: 32,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Write your review here...',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _comment = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitComment,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Submit Review',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_comments.isEmpty)
                      Center(
                        child: Text(
                          'No reviews yet. Be the first to review!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (context, index) => Divider(height: 32),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final user = _userCache[comment.userId];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: Text(
                                      (user?.firstName.isNotEmpty == true
                                              ? user!.firstName[0]
                                              : 'U')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user?.firstName ?? 'Unknown User',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('MMM d, yyyy').format(comment.createdAt),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < comment.stars
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  );
                                }),
                              ),
                              SizedBox(height: 8),
                              Text(
                                comment.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
