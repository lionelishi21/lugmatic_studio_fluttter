import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../providers/live_streaming_provider.dart';
import 'widgets/clash_opponent_view.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _chatController = TextEditingController();
  String _selectedCategory = 'music';

  static const _categories = ['music', 'podcast', 'qa', 'performance', 'other'];
  StreamSubscription? _invitationSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen for clash invitations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LiveStreamingProvider>();
      _invitationSub = provider.clashInvitations.listen((data) {
        if (mounted) _showClashInvitation(data);
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App returned to foreground, check if we need to refresh camera
      final provider = context.read<LiveStreamingProvider>();
      if (provider.isStreaming && provider.isCameraOn) {
        // Simple trick to force track to re-engage: toggle briefly or just notify
        // LiveKit usually handles this, but a manual refresh of the renderer helps
        setState(() {}); 
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _invitationSub?.cancel();
    _titleController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _startStreaming() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for your stream')),
      );
      return;
    }

    try {
      await context.read<LiveStreamingProvider>().startStreaming(
        _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start stream: $e')),
        );
      }
    }
  }

  Future<void> _stopStreaming() async {
    try {
      await context.read<LiveStreamingProvider>().stopStreaming();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end stream: $e')),
        );
      }
    }
  }

  void _showClashInvitation(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚔️ Clash Challenge!'),
        content: Text('${data['challenger']['name']} has challenged you to a lyrical war!'),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<LiveStreamingProvider>().rejectClash(data['clashId']);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<LiveStreamingProvider>().acceptClash(data['clashId']);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _sendChat() {
    if (_chatController.text.trim().isEmpty) return;
    context.read<LiveStreamingProvider>().sendChat(_chatController.text.trim());
    _chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final liveProvider = context.watch<LiveStreamingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Go Live'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.screenGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: liveProvider.isStreaming ? _buildStreamingView(liveProvider) : _buildSetupView(liveProvider),
        ),
      ),
    );
  }

  Widget _buildSetupView(LiveStreamingProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (provider.summary != null) _buildSummaryCard(provider),
        const SizedBox(height: 24),
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
          style: const TextStyle(color: AppColors.foreground),
          decoration: NeumorphicTheme.neumorphicInputDecoration(
            label: 'Stream Title',
            hint: 'e.g. Acoustic Night Live',
            prefixIcon: Icons.title,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          style: const TextStyle(color: AppColors.foreground),
          maxLines: 2,
          decoration: NeumorphicTheme.neumorphicInputDecoration(
            label: 'Description (optional)',
            hint: 'Tell fans what to expect...',
            prefixIcon: Icons.description_outlined,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.foreground),
          decoration: NeumorphicTheme.neumorphicInputDecoration(
            label: 'Category',
            prefixIcon: Icons.category_outlined,
          ),
          items: _categories.map((c) => DropdownMenuItem(
            value: c,
            child: Text(c[0].toUpperCase() + c.substring(1)),
          )).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val ?? 'music'),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: provider.isBusy ? null : _startStreaming,
            child: provider.isBusy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Go Live Now'),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(LiveStreamingProvider provider) {
    final summary = provider.summary!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              const Text('Stream Ended', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              IconButton(onPressed: () => provider.clearSummary(), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat('Duration', '${(summary['duration'] / 60).floor()}m'),
              _buildSummaryStat('Viewers', '${summary['totalViewers']}'),
              _buildSummaryStat('Gifts', '${summary['totalGiftsReceived']}'),
              _buildSummaryStat('Value', '${summary['totalGiftValue']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
      ],
    );
  }

  Widget _buildStreamingView(LiveStreamingProvider provider) {
    final track = provider.room?.localParticipant?.videoTrackPublications.firstOrNull?.track as LocalVideoTrack?;
    final clash = provider.activeClash;
    final inClash = provider.hasClashRoom && clash != null;

    return Column(
      children: [
        // Live Video View — split when in a clash
        Container(
          height: 400,
          clipBehavior: Clip.antiAlias,
          decoration: NeumorphicTheme.neumorphicDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.black,
          ),
          child: inClash
              ? Column(
                  children: [
                    // Top: artist's own camera
                    Expanded(
                      child: Stack(children: [
                        if (track != null)
                          VideoTrackRenderer(track, key: ValueKey(track.sid), fit: VideoViewFit.cover)
                        else
                          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        Positioned(
                          top: 8, left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                            child: const Row(children: [
                              Icon(Icons.circle, size: 8, color: Colors.redAccent),
                              SizedBox(width: 6),
                              Text('YOU', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                    Container(height: 2, color: Colors.white24),
                    // Bottom: opponent video from shared clash room
                    Expanded(
                      child: ClashOpponentView(
                        clashRoomUrl: provider.clashRoomUrl!,
                        clashRoomToken: provider.clashRoomToken!,
                        opponentUserId: provider.clashOpponentUserId ?? '',
                        opponentName: (clash['opponent'] is Map ? clash['opponent']['name'] : null) ?? 'Opponent',
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    if (track != null)
                      VideoTrackRenderer(
                        track,
                        key: ValueKey(track.sid),
                        fit: VideoViewFit.contain,
                      )
                    else
                      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              
              // Overlay info
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text('LIVE • ${provider.elapsedTime}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.group, size: 14, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('${provider.viewerCount}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),

              // Gift Alert Overlay
              if (provider.lastGift != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      final lastGift = provider.lastGift!;
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset((1.0 - value) * -50, 0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.purple, Colors.pink]),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundImage: lastGift['profilePicture'] != null 
                                    ? NetworkImage(lastGift['profilePicture']) as ImageProvider
                                    : null,
                                  child: lastGift['profilePicture'] == null 
                                    ? Text(lastGift['username'][0].toUpperCase()) 
                                    : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${lastGift['username']} sent ${lastGift['giftName']}! 🎁',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(10)),
                                  child: Text('+${lastGift['giftValue']}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Session Earnings
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Session Earnings', style: TextStyle(color: AppColors.mutedForeground)),
              Text('${provider.totalCoins} 🪙', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Chat View
        Container(
          height: 200,
          decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final msg = provider.messages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: '${msg['username']}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                            TextSpan(text: msg['message'], style: const TextStyle(color: AppColors.foreground, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _chatController,
                        style: const TextStyle(fontSize: 13, color: AppColors.foreground),
                        decoration: NeumorphicTheme.neumorphicInputDecoration(
                          label: 'Message',
                          hint: 'Send a message...',
                          prefixIcon: Icons.chat_bubble_outline,
                        ),
                        onFieldSubmitted: (_) => _sendChat(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sendChat,
                      icon: const Icon(Icons.send, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStreamControl(provider.isMicOn ? Icons.mic : Icons.mic_off, provider.isMicOn ? 'Mute' : 'Unmute', provider.toggleMic, active: provider.isMicOn),
            _buildStreamControl(provider.isCameraOn ? Icons.videocam : Icons.videocam_off, provider.isCameraOn ? 'Cam Off' : 'Cam On', provider.toggleCamera, active: provider.isCameraOn),
            _buildStreamControl(Icons.stop_circle, 'Stop', _stopStreaming, color: Colors.redAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStreamControl(IconData icon, String label, VoidCallback onTap, {Color? color, bool active = true}) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: onTap,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: color?.withOpacity(0.2) ?? (active ? AppColors.surfaceSubtle : Colors.red.withOpacity(0.1)),
            foregroundColor: color ?? (active ? AppColors.foreground : Colors.red),
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
      ],
    );
  }
}

