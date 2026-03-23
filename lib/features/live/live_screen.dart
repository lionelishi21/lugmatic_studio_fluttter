import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../data/services/live_stream_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final _liveService = LiveStreamService();
  bool _isStreaming = false;
  Room? _room;
  
  final _titleController = TextEditingController();

  Future<void> _startStreaming() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for your stream')),
      );
      return;
    }

    try {
      final streamData = await _liveService.createStream(title: _titleController.text);
      final String url = streamData['url'];
      final String token = streamData['token'];

      _room = Room();
      await _room!.connect(url, token);
      
      // Enable camera and microphone
      await _room!.localParticipant?.setCameraEnabled(true);
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      setState(() {
        _isStreaming = true;
      });
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start stream: $e')),
      );
    }
  }

  Future<void> _stopStreaming() async {
    await _room?.disconnect();
    setState(() {
      _isStreaming = false;
      _room = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Go Live')),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.screenGradient),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isStreaming ? _buildStreamingView() : _buildSetupView(),
        ),
      ),
    );
  }

  Widget _buildSetupView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.videocam_outlined, size: 80, color: AppColors.primary),
        const SizedBox(height: 24),
        const Text(
          'Start a Live Session',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Connect with your fans and earn gifts in real-time.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 48),
        TextFormField(
          controller: _titleController,
          decoration: NeumorphicTheme.neumorphicInputDecoration(
            label: 'Stream Title',
            hint: 'e.g. Acoustic Night Live',
            prefixIcon: Icons.title,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startStreaming,
            child: const Text('Go Live Now'),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingView() {
    final track = _room?.localParticipant?.videoTrackPublications.firstOrNull?.track as LocalVideoTrack?;

    return Column(
      children: [
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: NeumorphicTheme.neumorphicDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black,
            ),
            child: Stack(
              children: [
                if (track != null)
                  VideoRenderer(track)
                else
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Initializing camera...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                
                // Overlay info
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, py: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Total gifts display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: NeumorphicTheme.neumorphicDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Session Earnings'),
              Text('1,240 🪙', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStreamControl(Icons.mic, 'Mute', () {}),
            _buildStreamControl(Icons.videocam, 'Flip', () {}),
            _buildStreamControl(Icons.stop_circle, 'Stop', _stopStreaming, color: Colors.redAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStreamControl(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: onTap,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: color?.withOpacity(0.2) ?? AppColors.surfaceSubtle,
            foregroundColor: color ?? AppColors.foreground,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
