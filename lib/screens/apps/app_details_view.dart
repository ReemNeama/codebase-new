import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:utb_codebase/core/models/project.dart';
import 'package:utb_codebase/core/models/user.dart';
import '../../widgets/detail_header.dart';
import '../../widgets/gallery_section.dart';
import '../../widgets/stats_section.dart';
import '../../widgets/user_section.dart';

class AppDetailsView extends StatelessWidget {
  final Project app;
  final User? appOwner;
  final Map<String, User> userCache;
  final bool isProjectOwner;
  final VoidCallback onAddScreenshot;
  final Function(String) onRemoveScreenshot;
  final VoidCallback onAddCollaborator;
  final Function(User) onRemoveCollaborator;
  final VoidCallback onEdit;

  const AppDetailsView({
    Key? key,
    required this.app,
    required this.appOwner,
    required this.userCache,
    required this.isProjectOwner,
    required this.onAddScreenshot,
    required this.onRemoveScreenshot,
    required this.onAddCollaborator,
    required this.onRemoveCollaborator,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildTeamSection(),
            _buildStatsSection(),
            _buildScreenshotsSection(),
            _buildDetailsSection(context),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      title: Text(
        app.name,
        style: const TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        if (isProjectOwner)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: onEdit,
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DetailHeader(
      title: app.name,
      description: app.description,
      createdAt: app.createdAt,
      categories: [app.category],
      status: app.status,
      logo: Hero(
        tag: 'app_logo_${app.id}',
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
            child: app.logoUrl != null
                ? Image.network(
                    app.logoUrl!,
                    fit: BoxFit.cover,
                  )
                : Image.asset('assets/default_logo.png'),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSection() {
    return UserSection(
      owner: appOwner ?? User.empty(),
      collaborators: app.collaborators.map((id) {
        return userCache[id] ??
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
      canModify: isProjectOwner,
      onAddCollaborator: isProjectOwner ? onAddCollaborator : null,
      onRemoveCollaborator: isProjectOwner ? onRemoveCollaborator : null,
    );
  }

  Widget _buildStatsSection() {
    return StatsSection(
      stats: [
        StatItem(
          label: 'Stars',
          value: app.stars.toString(),
          icon: Icons.star,
          color: Colors.amber,
        ),
        StatItem(
          label: 'Views',
          value: app.views.toString(),
          icon: Icons.remove_red_eye,
        ),
        StatItem(
          label: 'Downloads',
          value: app.downloads.toString(),
          icon: Icons.download,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildScreenshotsSection() {
    return GallerySection(
      images: app.screenshotsUrl,
      title: 'Screenshots',
      imageHeight: 200,
      canModify: isProjectOwner,
      onAddImage: isProjectOwner ? onAddScreenshot : null,
      onRemoveImage: isProjectOwner ? onRemoveScreenshot : null,
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Card(
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
              DateFormat('dd/MM/yyyy').format(app.createdAt),
            ),
            _buildDetailRow(
              Icons.category,
              'Category',
              app.category,
            ),
            _buildDetailRow(
              Icons.public,
              'Status',
              app.status,
            ),
            if (app.logoUrl != null)
              _buildDetailRow(
                Icons.android,
                'APK',
                'Available',
              ),
            if (app.downloadUrlForIphone != null)
              _buildDetailRow(
                Icons.apple,
                'IPA',
                'Available',
              ),
          ],
        ),
      ),
    );
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
}
