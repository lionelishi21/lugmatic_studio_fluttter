import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/track_provider.dart';
import '../../data/models/track_model.dart';
import 'track_analytics_screen.dart';
import 'upload_track_screen.dart';
import '../search/search_screen.dart';

class TracksListScreen extends StatefulWidget {
  const TracksListScreen({super.key});

  @override
  State<TracksListScreen> createState() => _TracksListScreenState();
}

class _TracksListScreenState extends State<TracksListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final artistId = auth.user?['artistId'] ?? auth.user?['_id'];
      if (artistId != null) {
        context.read<TrackProvider>().fetchTracks(artistId.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Library',
                                style: TextStyle(
                                  color: AppColors.foreground,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your tracks and view performance',
                                style: TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: AppColors.foreground, size: 24),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<TrackProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.tracks.isEmpty) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }

                    if (provider.error != null && provider.tracks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 16),
                            Text(provider.error!, style: const TextStyle(color: Colors.redAccent)),
                            TextButton(
                              onPressed: () {
                                final auth = context.read<AuthProvider>();
                                provider.fetchTracks(auth.user?['artistId'] ?? auth.user?['_id']);
                              },
                              child: const Text('Retry'),
                            )
                          ],
                        ),
                      );
                    }

                    if (provider.tracks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.music, color: AppColors.mutedForeground.withOpacity(0.3), size: 64),
                            const SizedBox(height: 24),
                            const Text(
                              'No tracks found in your library.',
                              style: TextStyle(color: AppColors.mutedForeground, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        final auth = context.read<AuthProvider>();
                        await provider.fetchTracks(auth.user?['artistId'] ?? auth.user?['_id']);
                      },
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: provider.tracks.length,
                        itemBuilder: (context, index) {
                          final track = provider.tracks[index];
                          return _buildTrackItem(track);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
        icon: const Icon(Icons.cloud_upload_outlined, color: Colors.black),
        label: const Text('UPLOAD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTrackItem(Track track) {
    final dateFormat = DateFormat.yMMMd();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrackAnalyticsScreen(track: track),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Cover Art
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: track.coverArtUrl != null || track.coverArt != null
                  ? Image.network(
                      track.coverArtUrl ?? track.coverArt!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => _buildPlaceholderCover(),
                    )
                  : _buildPlaceholderCover(),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusBadge(track.status),
                      const SizedBox(width: 8),
                      if (track.role != null) ...[
                        _buildRoleBadge(track.role!, track.share),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        dateFormat.format(track.createdAt),
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(FontAwesomeIcons.play, color: AppColors.primary, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      NumberFormat.compact().format(track.playCount),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.mutedForeground, size: 20),
                  color: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (value) async {
                    if (value == 'analytics') {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TrackAnalyticsScreen(track: track),
                      ));
                    } else if (value == 'share') {
                      final url = 'https://studio.lugmaticmusic.com/share/song/${track.id}';
                      Share.share(
                        'Listen to "${track.name}" on Lugmatic 🎵\n$url',
                        subject: track.name,
                      );
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A2E),
                          title: const Text('Delete Track', style: TextStyle(color: Colors.white)),
                          content: Text('Delete "${track.name}"? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          await context.read<TrackProvider>().deleteTrack(track.id);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Track deleted'), backgroundColor: Colors.red),
                          );
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete: $e')),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'analytics', child: Row(children: [
                      Icon(Icons.bar_chart, size: 16, color: Colors.white70),
                      SizedBox(width: 10),
                      Text('Analytics', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ])),
                    const PopupMenuItem(value: 'share', child: Row(children: [
                      Icon(Icons.share_rounded, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 10),
                      Text('Share', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ])),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(FontAwesomeIcons.music, color: AppColors.primary, size: 24),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.greenAccent;
        break;
      case 'pending':
        color = Colors.amberAccent;
        break;
      case 'rejected':
        color = Colors.redAccent;
        break;
      default:
        color = AppColors.mutedForeground;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, double? share) {
    final bool isPrimary = role.toLowerCase() == 'primary';
    final Color color = isPrimary ? AppColors.primary : Colors.blueAccent;
    final String shareText = share != null ? ' (${share.round()}%)' : '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        '${role.toUpperCase()}$shareText',
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
