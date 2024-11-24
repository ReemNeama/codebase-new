import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:utb_codebase/core/models/project.dart';
import 'package:utb_codebase/core/models/user.dart';
import 'package:utb_codebase/widgets/detail_header.dart';
import 'package:utb_codebase/widgets/gallery_section.dart';
import 'package:utb_codebase/widgets/stats_section.dart';
import 'package:utb_codebase/widgets/user_section.dart';

class AppDetailsView extends StatelessWidget {
  final Project app;
  final User? appOwner;
  final Map<String, User> userCache;
  final bool isProjectOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onAddCollaborator;
  final Function(User)? onRemoveCollaborator;
  final VoidCallback? onAddScreenshot;
  final Function(String)? onRemoveScreenshot;

  const AppDetailsView({
    Key? key,
    required this.app,
    required this.appOwner,
    required this.userCache,
    required this.isProjectOwner,
    this.onEdit,
    this.onAddCollaborator,
    this.onRemoveCollaborator,
    this.onAddScreenshot,
    this.onRemoveScreenshot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.primaryColor,
        title: Text(
          app.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isProjectOwner)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: onEdit,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: theme.primaryColor.withOpacity(0.1),
            child: Text(
              'App Details',
              style: TextStyle(
                fontSize: 14,
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Implement refresh logic in parent widget
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    _buildTeamSection(),
                    _buildStatsSection(),
                    _buildScreenshotsSection(),
                    _buildDetailsSection(context),
                  ]
                      .animate(interval: const Duration(milliseconds: 100))
                      .fadeIn(duration: const Duration(milliseconds: 300))
                      .slideX(begin: -0.1, end: 0),
                ),
              ),
            ),
          ),
        ],
      ),
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
                ? CachedNetworkImage(
                    imageUrl: app.logoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
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
      ),
    );
  }

  Widget _buildTeamSection() {
    return UserSection(
      owner: appOwner ?? User.empty(),
      collaborators: app.collaborators.map((id) {
        return userCache[id] ?? User.empty();
      }).toList(),
      title: 'App Team',
      canModify: isProjectOwner,
      onAddCollaborator: onAddCollaborator,
      onRemoveCollaborator: onRemoveCollaborator,
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
      onAddImage: onAddScreenshot,
      onRemoveImage: onRemoveScreenshot,
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: theme.textTheme.headlineSmall?.copyWith(
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
              color: app.getStatusColor(),
            ),
            if (app.isGraduation)
              _buildDetailRow(
                Icons.school,
                'Type',
                'Graduation Project',
                color: Colors.purple,
              ),
            if (app.downloadUrl != null || app.downloadUrlForIphone != null)
              _buildDownloadButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (app.downloadUrl != null)
            ElevatedButton.icon(
              onPressed: () async {
                final url = Uri.parse(app.downloadUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              icon: const Icon(Icons.android),
              label: const Text('Download for Android'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          if (app.downloadUrl != null && app.downloadUrlForIphone != null)
            const SizedBox(height: 8),
          if (app.downloadUrlForIphone != null)
            ElevatedButton.icon(
              onPressed: () async {
                final url = Uri.parse(app.downloadUrlForIphone!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              icon: const Icon(Icons.apple),
              label: const Text('Download for iOS'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
