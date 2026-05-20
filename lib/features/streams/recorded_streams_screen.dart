import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';

class RecordedStreamsScreen extends StatefulWidget {
  const RecordedStreamsScreen({super.key});

  @override
  State<RecordedStreamsScreen> createState() => _RecordedStreamsScreenState();
}

class _RecordedStreamsScreenState extends State<RecordedStreamsScreen> {
  final _api = ApiClient();
  List<dynamic> _streams = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = false;
  String _category = 'All';

  static const _categories = ['All', 'Music', 'Dancehall', 'Reggae', 'Podcast', 'Other'];

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
  }

  Future<void> _fetch({bool reset = false}) async {
    if (reset) {
      setState(() { _isLoading = true; _error = null; _page = 1; });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final params = {
        'page': reset ? 1 : _page,
        'limit': 20,
        if (_category != 'All') 'category': _category.toLowerCase(),
      };
      final res = await _api.dio.get('/live-stream/recorded', queryParameters: params);
      final body = res.data;
      final List<dynamic> incoming = (body['data'] ?? []) as List<dynamic>;
      final pagination = body['pagination'];
      final total = pagination?['total'] ?? 0;

      if (mounted) {
        setState(() {
          _streams = reset ? incoming : [..._streams, ...incoming];
          _page = reset ? 2 : _page + 1;
          _hasMore = _streams.length < total;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load streams';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _openStream(dynamic stream) async {
    final recordingUrl = stream['recordingUrl'] as String?;
    if (recordingUrl == null || recordingUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording not available yet'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }
    final uri = Uri.tryParse(recordingUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _selectCategory(String cat) {
    if (cat == _category) return;
    setState(() => _category = cat);
    _fetch(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Past Streams',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.foreground),
            onPressed: () => _fetch(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = cat == _category;
                return GestureDetector(
                  onTap: () => _selectCategory(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppColors.mutedForeground,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.mutedForeground)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _fetch(reset: true),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_streams.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetch(reset: true),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Column(
                children: [
                  Icon(FontAwesomeIcons.video, size: 56, color: AppColors.muted),
                  const SizedBox(height: 20),
                  const Text(
                    'No recorded streams yet',
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Go live and your recordings will appear here',
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetch(reset: true),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        itemCount: _streams.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _streams.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _isLoadingMore
                    ? const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)
                    : OutlinedButton(
                        onPressed: _fetch,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Load More'),
                      ),
              ),
            );
          }
          return _StreamCard(stream: _streams[i], onTap: () => _openStream(_streams[i]));
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StreamCard extends StatelessWidget {
  final dynamic stream;
  final VoidCallback onTap;

  const _StreamCard({required this.stream, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final coverImage = stream['coverImage'] as String?;
    final title = (stream['title'] ?? 'Untitled Stream') as String;
    final category = (stream['category'] ?? '') as String;
    final hostName = (stream['host']?['name'] ?? 'Artist') as String;
    final endTime = stream['endTime'] != null
        ? DateTime.tryParse(stream['endTime'].toString())?.toLocal()
        : null;
    final durationSec = (stream['duration'] ?? 0) as int;
    final viewers = (stream['totalViewers'] ?? 0) as int;
    final hasRecording = (stream['recordingUrl'] as String?)?.isNotEmpty ?? false;

    String durationStr;
    if (durationSec >= 3600) {
      final h = durationSec ~/ 3600;
      final m = (durationSec % 3600) ~/ 60;
      durationStr = '${h}h ${m}m';
    } else if (durationSec >= 60) {
      durationStr = '${durationSec ~/ 60}m';
    } else {
      durationStr = '${durationSec}s';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  coverImage != null && coverImage.isNotEmpty
                      ? Image.network(
                          coverImage,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
                        )
                      : _thumbnailPlaceholder(),
                  // Play icon overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasRecording ? FontAwesomeIcons.play : FontAwesomeIcons.hourglass,
                          color: hasRecording ? Colors.white : Colors.white54,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  // Category badge
                  if (category.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.user, size: 11, color: AppColors.mutedForeground),
                      const SizedBox(width: 5),
                      Text(
                        hostName,
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                      ),
                      if (endTime != null) ...[
                        const Text('  ·  ', style: TextStyle(color: AppColors.mutedForeground)),
                        Text(
                          DateFormat.MMMd().format(endTime),
                          style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                        ),
                      ],
                      const Spacer(),
                      const FaIcon(FontAwesomeIcons.clock, size: 11, color: AppColors.mutedForeground),
                      const SizedBox(width: 4),
                      Text(durationStr, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                      const SizedBox(width: 10),
                      const FaIcon(FontAwesomeIcons.eye, size: 11, color: AppColors.mutedForeground),
                      const SizedBox(width: 4),
                      Text(
                        NumberFormat.compact().format(viewers),
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder() => Container(
    height: 160,
    width: double.infinity,
    color: AppColors.muted,
    child: const Center(
      child: FaIcon(FontAwesomeIcons.video, color: AppColors.mutedForeground, size: 32),
    ),
  );
}
