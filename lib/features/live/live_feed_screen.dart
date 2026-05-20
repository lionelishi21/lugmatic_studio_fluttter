import 'package:flutter/material.dart';
import '../../data/services/live_stream_service.dart';
import '../../core/constants/app_colors.dart';
import 'live_stream_viewer.dart';
import '../streams/recorded_streams_screen.dart';

class LiveFeedScreen extends StatefulWidget {
  const LiveFeedScreen({super.key});

  @override
  State<LiveFeedScreen> createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends State<LiveFeedScreen> {
  final _liveService = LiveStreamService();
  List<dynamic> _streams = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchStreams();
  }

  Future<void> _fetchStreams() async {
    try {
      final streams = await _liveService.getActiveStreams();
      if (mounted) {
        setState(() {
          _streams = streams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load streams: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: _PastStreamsButton(),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _fetchStreams, child: const Text('Retry')),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: _PastStreamsButton(),
            ),
          ],
        ),
      );
    }

    if (_streams.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: RefreshIndicator(
                onRefresh: _fetchStreams,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off_outlined, color: Colors.white24, size: 80),
                        SizedBox(height: 16),
                        Text('No live artists right now', style: TextStyle(color: Colors.white70, fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Pull down to refresh', style: TextStyle(color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: _PastStreamsButton(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _streams.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final stream = _streams[index];
              return LiveStreamViewer(
                streamId: stream['_id'],
                hostName: stream['host']['name'] ?? 'Artist',
                title: stream['title'] ?? 'Untitled Stream',
                description: stream['description'] ?? '',
                hostImage: stream['host']['image'] ?? stream['hostUser']?['profilePicture'],
                isActive: index == _currentPage,
              );
            },
          ),
          // Past Streams button overlay (top-right, below status bar)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _PastStreamsButton(),
          ),
        ],
      ),
    );
  }
}

class _PastStreamsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RecordedStreamsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library_outlined, color: Colors.white70, size: 14),
            SizedBox(width: 6),
            Text('Past Streams', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
