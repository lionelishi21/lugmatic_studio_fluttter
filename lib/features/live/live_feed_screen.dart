import 'package:flutter/material.dart';
import '../../data/services/live_stream_service.dart';
import '../../core/constants/app_colors.dart';
import 'live_stream_viewer.dart';

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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchStreams, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_streams.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
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
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
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
    );
  }
}
