import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/podcast_provider.dart';
import '../tracks/upload_track_screen.dart';

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final artistId = auth.user?['artistId'] ?? auth.user?['_id'];
      if (artistId != null) {
        context.read<PodcastProvider>().fetchPodcasts(artistId.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Podcasts',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your episodes and insights',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<PodcastProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.podcasts.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (provider.error != null && provider.podcasts.isEmpty) {
                    return Center(child: Text(provider.error!, style: const TextStyle(color: Colors.redAccent)));
                  }

                  if (provider.podcasts.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _load(),
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: provider.podcasts.length,
                      itemBuilder: (context, index) {
                        final podcast = provider.podcasts[index];
                        return _buildPodcastItem(podcast);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadTrackScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.mic, color: Colors.black),
        label: const Text('NEW EPISODE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.microphone, color: AppColors.mutedForeground.withOpacity(0.2), size: 64),
          const SizedBox(height: 24),
          const Text(
            'No podcast episodes yet.',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadTrackScreen()));
            },
            child: const Text('Upload your first one', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastItem(dynamic p) {
    final bool isPublished = p['isPublished'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: p['coverImage'] != null
                ? Image.network(p['coverImage'], width: 64, height: 64, fit: BoxFit.cover)
                : Container(
                    width: 64, height: 64, color: AppColors.card,
                    child: const Icon(FontAwesomeIcons.microphone, color: AppColors.primary, size: 24),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['title'] ?? 'Untitled Episode',
                  style: const TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isPublished ? Colors.greenAccent : Colors.amberAccent).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPublished ? 'PUBLISHED' : 'DRAFT',
                        style: TextStyle(
                          color: isPublished ? Colors.greenAccent : Colors.amberAccent,
                          fontSize: 8, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${p['listeners'] ?? 0} listeners',
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isPublished ? Icons.pause_circle_outline : Icons.play_circle_outline, color: AppColors.primary),
            onPressed: () {
              context.read<PodcastProvider>().togglePublish(p['_id'], isPublished);
            },
          ),
        ],
      ),
    );
  }
}
