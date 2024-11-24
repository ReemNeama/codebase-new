// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors, library_private_types_in_public_api, avoid_print, prefer_const_constructors, prefer_final_fields, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:utb_codebase/core/crudModel/project_crud.dart';
import 'package:utb_codebase/widgets/comment_card.dart';
import 'package:utb_codebase/widgets/detail_header.dart';
import 'package:utb_codebase/widgets/star_rating.dart';

import '../../core/crudModel/user_crud.dart';
import '../../core/models/project.dart';
import '../../core/crudModel/comment_crud.dart';
import '../../core/models/comment.dart';
import '../../core/models/user.dart';
import '../../widgets/user_section.dart';
import '../../widgets/stats_section.dart';
import '../../widgets/gallery_section.dart';

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
  final _projectCrud = CRUDProject();

  List<Comment> _comments = [];
  Map<String, User?> _userCache = {};
  User? _appOwner;
  bool _isSubmitting = false;
  bool _hasUserReviewed = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _fetchComments(),
        _fetchAppOwner(),
        _checkUserReview(),
      ]);
    } catch (e) {
      setState(() {
        _error = 'Failed to load app details';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading app details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await _commentCrud.getCommentsByProjectId(widget.app.id);
      if (!mounted) return;

      setState(() {
        _comments = comments;
      });
      await _fetchUsersForComments(comments);
    } catch (e) {
      print('Error fetching comments: $e');
      if (!mounted) return;
      throw e;
    }
  }

  Future<void> _fetchAppOwner() async {
    try {
      final owner = await _userCrud.getItemsById(widget.app.userId);
      if (!mounted) return;
      setState(() {
        _appOwner = owner;
      });
    } catch (e) {
      print('Error fetching app owner: $e');
      throw e;
    }
  }

  Future<void> _checkUserReview() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final hasReviewed = await _commentCrud.hasUserCommentedOnProject(
          user.uid,
          widget.app.id,
        );
        if (!mounted) return;
        setState(() {
          _hasUserReviewed = hasReviewed;
        });
      }
    } catch (e) {
      print('Error checking user review: $e');
      throw e;
    }
  }

  Future<void> _submitComment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      _formKey.currentState!.save();
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not authenticated';

      final hasReviewed = await _commentCrud.hasUserCommentedOnProject(
        user.uid,
        widget.app.id,
      );

      if (hasReviewed) {
        throw 'You have already reviewed this app';
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
      await _updateProjectRating();

      _formKey.currentState!.reset();
      setState(() {
        _rating = 3.0;
        _hasUserReviewed = true;
      });

      await _fetchComments();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _updateProjectRating() async {
    try {
      final avgRating = await _commentCrud.getAverageRating(widget.app.id);
      final updatedApp = widget.app.copyWith(stars: avgRating.round());
      await _projectCrud.updateItem(updatedApp, updatedApp.id);
    } catch (e) {
      print('Error updating project rating: $e');
    }
  }

  Future<void> _fetchUsersForComments(List<Comment> comments) async {
    final userProvider = context.read<CRUDUser>();
    final uniqueUserIds = comments.map((c) => c.userId).toSet();

    for (var userId in uniqueUserIds) {
      if (!_userCache.containsKey(userId)) {
        try {
          final user = await userProvider.getItemsById(userId);
          if (!mounted) return;
          setState(() {
            _userCache[userId] = user;
          });
        } catch (e) {
          print('Error fetching user $userId: $e');
        }
      }
    }
  }

  Future<void> _addScreenshot() async {
    // TODO: Implement screenshot upload functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screenshot upload not implemented yet'),
      ),
    );
  }

  Future<void> _removeScreenshot(String imageUrl) async {
    // TODO: Implement screenshot removal functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screenshot removal not implemented yet'),
      ),
    );
  }

  bool _isProjectOwner() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    return currentUser != null && widget.app.userId == currentUser.uid;
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCollaboratorDialog() async {
    final TextEditingController emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Collaborator'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter collaborator\'s email',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email address';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final email = emailController.text.trim();
                  final user = await _userCrud.getUserByEmail(email);

                  if (user == null) {
                    throw 'User not found';
                  }

                  if (widget.app.collaborators.contains(user.id)) {
                    throw 'User is already a collaborator';
                  }

                  final updatedCollaborators =
                      List<String>.from(widget.app.collaborators)..add(user.id);
                  final updatedApp = widget.app.copyWith(
                    collaborators: updatedCollaborators,
                  );

                  await _projectCrud.updateItem(updatedApp, updatedApp.id);

                  Navigator.pop(context);
                  setState(() {});

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Collaborator added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to add collaborator: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeCollaborator(User user) async {
    try {
      final updatedCollaborators = List<String>.from(widget.app.collaborators)
        ..remove(user.id);
      final updatedApp = widget.app.copyWith(
        collaborators: updatedCollaborators,
      );

      await _projectCrud.updateItem(updatedApp, updatedApp.id);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Collaborator removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove collaborator: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                Navigator.pushNamed(
                  context,
                  '/app/edit',
                  arguments: widget.app,
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailHeader(
              title: widget.app.name,
              description: widget.app.description,
              createdAt: widget.app.createdAt,
              categories: [widget.app.category],
              status: widget.app.status,
              logo: Hero(
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
            ),
            // App Owner & Collaborators Section
            UserSection(
              owner: _appOwner ?? User.empty(),
              collaborators: widget.app.collaborators.map((id) {
                return _userCache[id] ??
                    User(
                      id: id,
                      firstName: 'Unknown',
                      lastName: 'User',
                      email: '',
                      skills: const [],
                      programmingLanguages: const [],
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
              }).toList(),
              title: 'App Team',
              canModify: _isProjectOwner(),
              onAddCollaborator:
                  _isProjectOwner() ? () => _showAddCollaboratorDialog() : null,
              onRemoveCollaborator: _isProjectOwner()
                  ? (user) => _removeCollaborator(user)
                  : null,
            ),
            // Stats Section
            StatsSection(
              stats: [
                StatItem(
                  label: 'Stars',
                  value: widget.app.stars.toString(),
                  icon: Icons.star,
                  color: Colors.amber,
                ),
                StatItem(
                  label: 'Views',
                  value: widget.app.views.toString(),
                  icon: Icons.remove_red_eye,
                ),
                StatItem(
                  label: 'Downloads',
                  value: widget.app.downloads.toString(),
                  icon: Icons.download,
                  color: Colors.green,
                ),
              ],
            ),
            // Screenshots Section
            GallerySection(
              images: widget.app.screenshotsUrl,
              title: 'Screenshots',
              imageHeight: 200,
              canModify: _isProjectOwner(),
              onAddImage: _isProjectOwner() ? _addScreenshot : null,
              onRemoveImage: _isProjectOwner() ? _removeScreenshot : null,
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
                        fontSize: 24,
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
                            onPressed: () async {
                              try {
                                // Add download tracking
                                final updatedApp = widget.app.copyWith(
                                  downloads: widget.app.downloads + 1,
                                );
                                await _projectCrud.updateItem(
                                    updatedApp, updatedApp.id);

                                // Launch download URL
                                if (widget.app.downloadUrl != null) {
                                  final url = widget.app.downloadUrl!;
                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(Uri.parse(url));
                                  } else {
                                    throw 'Could not launch $url';
                                  }
                                } else {
                                  throw 'Download URL not available';
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to download: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
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
                    if (firebase_auth.FirebaseAuth.instance.currentUser !=
                            null &&
                        firebase_auth.FirebaseAuth.instance.currentUser?.uid !=
                            widget.app.userId &&
                        !_hasUserReviewed)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rate this app',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 8),
                              StarRating(
                                rating: _rating.round(),
                                size: 24,
                                isEditable: true,
                                onRatingChanged: (rating) {
                                  setState(() {
                                    _rating = rating.toDouble();
                                  });
                                },
                              ),
                              SizedBox(height: 16),
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
                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _isSubmitting ? null : _submitComment,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
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
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
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
                      ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else if (_error != null)
                      Center(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      )
                    else if (_comments.isEmpty)
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
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final user = _userCache[comment.userId];
                          return CommentCard(
                            comment: comment,
                            user: user,
                            projectName: widget.app.name,
                            showProject: false,
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
